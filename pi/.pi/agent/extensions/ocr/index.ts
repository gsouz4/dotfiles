import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { execFile } from "node:child_process";
import { promisify } from "node:util";
import { writeFile, unlink, copyFile } from "node:fs/promises";
import { join } from "node:path";
import { tmpdir } from "node:os";

const execFileAsync = promisify(execFile);

export default function (pi: ExtensionAPI) {
  pi.on("before_agent_start", async (event, ctx) => {
    // Only trigger when images are attached
    if (!event.images || event.images.length === 0) return;

    // Check if model supports images
    const model = ctx.model;
    if (!model) return;

    const supportsImages = model.input?.includes("image");
    if (supportsImages) return; // Model can see images natively, no OCR needed

    // Model doesn't support images — run OCR on each image
    const ocrResults: string[] = [];

    for (let i = 0; i < event.images.length; i++) {
      const image = event.images[i];
      try {
        const text = await ocrImage(image);
        if (text.trim()) {
          ocrResults.push(`[Image ${i + 1} OCR]\n${text.trim()}`);
        } else {
          ocrResults.push(
            `[Image ${i + 1} OCR]\nNo text detected. This image likely contains a drawing, diagram, or photo. Tesseract cannot extract meaning from non-text images. Use a vision model for this type of content.`
          );
        }
      } catch (err) {
        ocrResults.push(
          `[Image ${i + 1} OCR]\nOCR failed: ${err instanceof Error ? err.message : String(err)}`
        );
      }
    }

    if (ocrResults.length === 0) return;

    // Inject OCR text as a persistent message into the conversation
    const ocrText = ocrResults.join("\n\n---\n\n");

    return {
      message: {
        customType: "ocr-fallback",
        content: `The current model (${model.id}) does not support image input. Tesseract OCR was used to extract text from the attached image(s):\n\n${ocrText}`,
        display: true,
      },
    };
  });
}

async function ocrImage(image: { type: string; source: { type: string; data?: string; url?: string; mediaType?: string } }): Promise<string> {
  // Handle base64 images
  if (image.source.type === "base64" && image.source.data) {
    const buffer = Buffer.from(image.source.data, "base64");
    const ext = mediaTypeToExt(image.source.mediaType || image.type);
    const tmpPath = join(tmpdir(), `pi-ocr-${Date.now()}.${ext}`);
    try {
      await writeFile(tmpPath, buffer);
      const text = await runTesseract(tmpPath);
      return text;
    } finally {
      await unlink(tmpPath).catch(() => {});
    }
  }

  // Handle URL images — download to temp file
  if (image.source.type === "url" && image.source.url) {
    const ext = mediaTypeToExt(image.source.mediaType || image.type);
    const tmpPath = join(tmpdir(), `pi-ocr-url-${Date.now()}.${ext}`);
    try {
      // Use curl to download
      const { stdout } = await execFileAsync("curl", ["-sL", "-o", tmpPath, image.source.url]);
      const text = await runTesseract(tmpPath);
      return text;
    } finally {
      await unlink(tmpPath).catch(() => {});
    }
  }

  // Handle file path images (some providers pass local paths)
  if (image.source.type === "file" && (image.source as any).path) {
    return runTesseract((image.source as any).path);
  }

  throw new Error(`Unsupported image source type: ${image.source.type}`);
}

async function runTesseract(imagePath: string): Promise<string> {
  // Try default PSM first
  let text = await tesseractWithPsm(imagePath, 3);

  // If very short output, try PSM 6 (uniform block) for terminal/code
  if (text.trim().length < 5) {
    const alt = await tesseractWithPsm(imagePath, 6);
    if (alt.trim().length > text.trim().length) {
      text = alt;
    }
  }

  // If still very short, try enhanced preprocessing
  if (text.trim().length < 5) {
    const enhanced = await enhanceAndOcr(imagePath);
    if (enhanced.trim().length > text.trim().length) {
      text = enhanced;
    }
  }

  return cleanupOcrOutput(text);
}

async function tesseractWithPsm(imagePath: string, psm: number): Promise<string> {
  try {
    const { stdout } = await execFileAsync("tesseract", [imagePath, "stdout", "--psm", String(psm)], {
      timeout: 30000,
      maxBuffer: 1024 * 1024,
    });
    return stdout;
  } catch {
    return "";
  }
}

async function enhanceAndOcr(imagePath: string): Promise<string> {
  const enhancedPath = join(tmpdir(), `pi-ocr-enhanced-${Date.now()}.png`);
  try {
    // Use Python/PIL to enhance
    await execFileAsync("python3", [
      "-c",
      `
from PIL import Image, ImageEnhance, ImageFilter
import sys
img = Image.open("${imagePath}")
img = img.convert('L')
img = img.resize((img.width * 3, img.height * 3), Image.LANCZOS)
img = ImageEnhance.Contrast(img).enhance(2.0)
img = img.filter(ImageFilter.SHARPEN)
img.save("${enhancedPath}")
`,
    ], { timeout: 15000 });

    return await tesseractWithPsm(enhancedPath, 6);
  } catch {
    return "";
  } finally {
    await unlink(enhancedPath).catch(() => {});
  }
}

function mediaTypeToExt(mediaType: string): string {
  const map: Record<string, string> = {
    "image/png": "png",
    "image/jpeg": "jpg",
    "image/gif": "gif",
    "image/webp": "webp",
    "image/bmp": "bmp",
    "image/tiff": "tiff",
  };
  return map[mediaType] || "png";
}

function cleanupOcrOutput(text: string): string {
  // Remove long numeric strings (likely memory addresses from terminal output)
  text = text.replace(/\b\d{10,}\b/g, "");

  // Fix common bracket manglings
  text = text.replace(/\{]/g, "[]");
  text = text.replace(/\[}/g, "[]");

  // Remove lines that are just noise (1-2 chars of symbols/numbers)
  text = text
    .split("\n")
    .filter((line) => {
      const trimmed = line.trim();
      if (trimmed.length === 0) return true; // keep blank lines
      if (trimmed.length <= 2 && /^[^a-zA-Z]*$/.test(trimmed)) return false; // noise like "OQ", "@@"
      return true;
    })
    .join("\n");

  return text;
}