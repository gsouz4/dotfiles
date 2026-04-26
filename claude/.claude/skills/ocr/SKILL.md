---
name: ocr
description: Automatically extract text from images using Tesseract when the model doesn't support images. This is a pi extension that hooks into before_agent_start and runs OCR transparently. No manual triggering needed. Only activates on vision-free models. Do NOT trigger manually — the extension handles it automatically.
---

# OCR Extension (Auto-Vision-Fallback)

**This runs automatically. No manual triggering needed.**

A pi extension at `~/.pi/agent/extensions/ocr/` that hooks into `before_agent_start`. When the active model doesn't support images but the user attaches one, it automatically:
1. Runs Tesseract OCR on each image
2. Cleans up the output (noise removal, bracket fixes)
3. Injects the extracted text as a context message into the conversation

## How it works

```
User pastes image
  └─► before_agent_start hook
        ├── Model supports images? → Do nothing. Model sees it natively.
        └── Model text-only? → Auto-run Tesseract
              ├── PSM 3 (default)
              ├── PSM 6 (if short output — for terminal/code)
              ├── Enhancement pipeline (if still short — scale 3x, contrast, sharpen)
              └── Inject OCR text as context message
```

## No manual action needed

The extension is auto-discovered from `~/.pi/agent/extensions/ocr/index.ts`. It runs on every prompt that includes images. If the model supports images (Claude, GPT-4o, Gemini), it does nothing. If the model is text-only (GLM, DeepSeek text modes), it automatically extracts and injects text.

## Limitations

| Image type | Tesseract quality | What happens |
|------------|-------------------|-------------|
| Screenshots, terminal, docs | ✅ Good | Text injected, LLM can work with it |
| Landing pages, UI | ⚠️ Gets gist, noisy | Partial text injected with cleanup |
| Dense math/code | ⚠️ Structure ok, details mangled | Approximate text, may have errors |
| Drawings, diagrams, photos | ❌ Empty output | Message says "no text detected, use vision model" |
| Handwriting | ❌ Unreliable | Likely garbage text or empty |

## Manual fallback

If the auto-OCR isn't enough, you can still run Tesseract manually:

```bash
tesseract <image_path> stdout 2>/dev/null
tesseract <image_path> stdout --psm 6 2>/dev/null  # terminal/code
```

## Installation

Requires Tesseract and Pillow:

```bash
brew install tesseract
pip3 install pillow
```