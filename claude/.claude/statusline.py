#!/usr/bin/env python3
"""Custom Claude Code status line.

Reads the Status hook JSON on stdin and renders a single line with:
  model  |  dir  |  git branch (+dirty)  |  session duration/lines  |  monthly spend / remaining

Monthly spend is accumulated across sessions in a small state file keyed by
session_id, since Claude Code only exposes the *current* session cost per render.
"""

import json
import os
import subprocess
import sys

# --- Config -----------------------------------------------------------------
MONTHLY_BUDGET_USD = 1000.0
STATE_FILE = os.path.expanduser("~/.claude/statusline-cost-state.json")

# ANSI colors (256-color)
DIM = "\033[2m"
RESET = "\033[0m"
CYAN = "\033[36m"
GREEN = "\033[32m"
YELLOW = "\033[33m"
RED = "\033[31m"
MAGENTA = "\033[35m"
BLUE = "\033[34m"


def read_input():
    try:
        return json.load(sys.stdin)
    except Exception:
        return {}


def current_month():
    # Local time; format YYYY-MM. Avoids importing datetime formatting surprises.
    import datetime

    return datetime.date.today().strftime("%Y-%m")


def update_and_sum_monthly(session_id, session_cost):
    """Persist this session's latest cost and return total spend for the month."""
    month = current_month()
    state = {}
    try:
        with open(STATE_FILE) as f:
            state = json.load(f)
    except Exception:
        state = {}

    if not isinstance(state, dict):
        state = {}

    # Prune entries from other months to keep the file small and the sum monthly.
    state = {
        sid: entry
        for sid, entry in state.items()
        if isinstance(entry, dict) and entry.get("month") == month
    }

    if session_id:
        state[session_id] = {"cost": session_cost, "month": month}

    # Atomic-ish write: temp file + rename.
    try:
        tmp = STATE_FILE + ".tmp"
        with open(tmp, "w") as f:
            json.dump(state, f)
        os.replace(tmp, STATE_FILE)
    except Exception:
        pass

    return sum(float(e.get("cost", 0) or 0) for e in state.values())


def git_segment(cwd):
    try:
        branch = subprocess.run(
            ["git", "-C", cwd, "rev-parse", "--abbrev-ref", "HEAD"],
            capture_output=True, text=True, timeout=1,
        )
        if branch.returncode != 0:
            return None
        name = branch.stdout.strip()
        dirty = subprocess.run(
            ["git", "-C", cwd, "status", "--porcelain"],
            capture_output=True, text=True, timeout=1,
        )
        mark = f"{YELLOW}*{RESET}" if dirty.stdout.strip() else ""
        return f"{MAGENTA} {name}{RESET}{mark}"
    except Exception:
        return None


def fmt_duration(ms):
    try:
        s = int(ms) // 1000
    except Exception:
        return None
    if s < 60:
        return f"{s}s"
    m, s = divmod(s, 60)
    if m < 60:
        return f"{m}m{s:02d}s"
    h, m = divmod(m, 60)
    return f"{h}h{m:02d}m"


def main():
    data = read_input()

    model = (data.get("model") or {}).get("display_name", "?")
    workspace = data.get("workspace") or {}
    cwd = workspace.get("current_dir") or data.get("cwd") or os.getcwd()
    dir_name = os.path.basename(cwd.rstrip("/")) or cwd

    cost = data.get("cost") or {}
    session_cost = float(cost.get("total_cost_usd", 0) or 0)
    duration = fmt_duration(cost.get("total_duration_ms"))
    added = cost.get("total_lines_added")
    removed = cost.get("total_lines_removed")

    session_id = data.get("session_id")
    monthly = update_and_sum_monthly(session_id, session_cost)
    remaining = MONTHLY_BUDGET_USD - monthly

    # Color the remaining by how much is left.
    pct_left = remaining / MONTHLY_BUDGET_USD if MONTHLY_BUDGET_USD else 0
    rem_color = GREEN if pct_left > 0.5 else (YELLOW if pct_left > 0.15 else RED)

    parts = []
    parts.append(f"{CYAN}\U0001F916 {model}{RESET}")
    parts.append(f"{BLUE} {dir_name}{RESET}")

    g = git_segment(cwd)
    if g:
        parts.append(g)

    # Session effort
    sess = []
    if duration:
        sess.append(duration)
    if added is not None or removed is not None:
        sess.append(f"+{added or 0}/-{removed or 0}")
    if sess:
        parts.append(f"{DIM} {' '.join(sess)}{RESET}")

    # Cost / budget
    spend = (
        f"{DIM}$ {RESET}"
        f"{rem_color}~${monthly:.2f}{RESET}"
        f"{DIM}/${MONTHLY_BUDGET_USD:.0f} est. "
        f"(${remaining:.2f} left){RESET}"
    )
    parts.append(spend)

    sep = f" {DIM}|{RESET} "
    sys.stdout.write(sep.join(parts))


if __name__ == "__main__":
    main()
