#!/usr/bin/env python3
"""Stop hook: registra um resumo bruto do turno em ~/vault/work/raw/YYYY-MM-DD.jsonl.
Sem LLM, sem custo. A consolidação em nota legível é feita pela skill /eod.
Vault alternativo: variável WORKLOG_VAULT."""
import sys, json, os, datetime, subprocess, re

vault = os.environ.get("WORKLOG_VAULT") or os.path.expanduser("~/vault/work")
os.makedirs(os.path.join(vault, "raw"), exist_ok=True)
try:
    hook = json.load(sys.stdin)
except Exception:
    sys.exit(0)

path = hook.get("transcript_path")
if not path or not os.path.exists(path):
    sys.exit(0)

entries = []
with open(path, encoding="utf-8", errors="replace") as f:
    for line in f:
        try:
            e = json.loads(line)
        except Exception:
            continue
        if e.get("type") in ("user", "assistant") and not e.get("isSidechain"):
            entries.append(e)

def is_prompt(e):
    if e.get("type") != "user" or e.get("isMeta"):
        return False
    c = e.get("message", {}).get("content")
    if isinstance(c, str):
        return True
    if isinstance(c, list):
        return any(b.get("type") == "text" for b in c) and not any(b.get("type") == "tool_result" for b in c)
    return False

# Último prompt real do usuário e tudo que veio depois
start = None
for i in range(len(entries) - 1, -1, -1):
    if is_prompt(entries[i]):
        start = i
        break
if start is None:
    sys.exit(0)

prompt_e = entries[start]
turn = [e for e in entries[start + 1:] if e.get("type") == "assistant"]
if not turn:
    sys.exit(0)

def text_of(c):
    if isinstance(c, str):
        return c
    return "\n".join(b.get("text", "") for b in c if b.get("type") == "text")

prompt = text_of(prompt_e["message"]["content"]).strip()
# Mensagens vindas de outras sessões/teammates ou skills automáticas não contam como trabalho do usuário
if prompt.startswith("Another Claude session sent a message") or prompt.startswith("<teammate-message"):
    sys.exit(0)

edits, commits, bash_n, tools = [], [], 0, set()
final_text = ""
for e in turn:
    for b in e["message"].get("content", []):
        t = b.get("type")
        if t == "text" and b.get("text", "").strip():
            final_text = b["text"].strip()
        elif t == "tool_use":
            name = b.get("name", "")
            tools.add(name)
            inp = b.get("input", {}) or {}
            if name in ("Edit", "Write", "MultiEdit", "NotebookEdit"):
                fp = inp.get("file_path") or inp.get("notebook_path")
                if fp and fp not in edits:
                    edits.append(fp)
            elif name == "Bash":
                bash_n += 1
                cmd = inp.get("command", "")
                if re.search(r"(?:^|[;&|(]\s*)git\s+(?:-C\s+\S+\s+)?commit\b", cmd, re.M):
                    m = re.search(r"-m\s+(?:\"([^\"]+)\"|'([^']+)'|\$\'([^\']+)\'|\$\(cat <<'?EOF'?\n(.+?)\n)", cmd, re.S)
                    msg = next((g for g in (m.groups() if m else ()) if g), None)
                    commits.append((msg or cmd)[:200].splitlines()[0])

# Filtro de ruído: turno sem ferramenta e com resposta curta não vira registro
if not tools and len(final_text) < 300:
    sys.exit(0)

cwd = hook.get("cwd") or turn[-1].get("cwd") or os.getcwd()
branch = turn[-1].get("gitBranch")
if branch == "HEAD":
    branch = None
if not branch:
    try:
        r = subprocess.run(["git", "-C", cwd, "rev-parse", "--abbrev-ref", "HEAD"],
                           capture_output=True, text=True, timeout=3)
        branch = r.stdout.strip() if r.returncode == 0 and r.stdout.strip() != "HEAD" else None
    except Exception:
        branch = None

turn_id = turn[-1].get("uuid")
now = datetime.datetime.now()
out = os.path.join(vault, "raw", now.strftime("%Y-%m-%d") + ".jsonl")

# Dedup: Stop também dispara em clear/resume/compact
if turn_id and os.path.exists(out):
    with open(out, encoding="utf-8") as f:
        if any(f'"turn_id": "{turn_id}"' in l for l in f):
            sys.exit(0)

rec = {
    "ts": now.strftime("%Y-%m-%dT%H:%M:%S"),
    "session": (hook.get("session_id") or "")[:8],
    "turn_id": turn_id,
    "project": os.path.basename(cwd.rstrip("/")),
    "cwd": cwd,
    "branch": branch,
    "prompt": prompt[:300],
    "tools": sorted(tools),
    "edits": edits[:30],
    "bash": bash_n,
    "commits": commits,
    "summary": final_text[:800],
}
with open(out, "a", encoding="utf-8") as f:
    f.write(json.dumps(rec, ensure_ascii=False) + "\n")
