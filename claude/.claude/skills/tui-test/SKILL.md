---
name: tui-test
description: Test TUI applications using tu (terminal-use). Launch apps in virtual terminals, take screenshots, type text, press keys, wait for conditions, and verify output. Use for smoke testing terminal UIs, interactive CLIs, and TUI apps. Trigger on phrases like "test the TUI", "terminal test", "tu test", "test in terminal", "smoke test the editor", "verify the UI".
---

# TUI Testing with `tu` (terminal-use)

Use `tu` CLI to test TUI applications in headless virtual terminals. Run all commands via the Bash tool.

## Core Workflow

```
1. Build the app
2. Launch in virtual terminal with `tu run`
3. Wait for UI to load with `tu wait`
4. Interact: type text, press keys
5. Screenshot and verify output
6. Clean up with `tu kill`
```

## Commands

```bash
tu run --name <id> --size 120x40 -- <command> [args]   # Launch app
tu kill --name <id>                                     # Kill session
tu list                                                 # List sessions
tu status --name <id>                                   # Check if alive
tu screenshot --name <id>                               # Capture screen (JSON)
tu type --name <id> "text"                              # Type literal text
tu press --name <id> <key> [key...]                     # Send keystrokes
tu paste --name <id> "text"                             # Paste with bracketed paste
tu wait --name <id> --text "pattern" --timeout 5000     # Wait for text on screen
tu cursor --name <id>                                   # Get cursor position
tu scrollback --name <id>                               # Full scrollback buffer
tu resize --name <id> --size 80x24                      # Resize terminal
```

## Key Names for `tu press`

```bash
# Modifiers
ctrl+y  ctrl+p  ctrl+j  ctrl+k  ctrl+c  ctrl+d

# Navigation
up  down  left  right  home  end  pageup  pagedown

# Common
enter  escape  tab  backspace  space  delete

# Function keys
f1  f2  f3 ...

# Multiple keys in sequence
tu press --name test ctrl+y enter escape
```

## Reading Screenshots

Screenshots return JSON. Extract the content field:

```bash
# Readable output
tu screenshot --name <id> | python3 -c "import sys,json; print(json.load(sys.stdin)['content'])"

# Just the right pane (columns 62+) for split-pane TUIs
tu screenshot --name <id> | python3 -c "
import sys,json
c = json.load(sys.stdin)['content']
for line in c.split('\n')[:30]:
    print(line[62:])
"
```

## Environment Variables

Pass env vars to the subprocess with `--env`:

```bash
# Source secrets and pass to tu
source ~/.secrets/env 2>/dev/null
tu run --name test --env "GROQ_API_KEY=$GROQ_API_KEY" -- ./app
```

## Waiting for State

Always wait for the app to be ready before interacting:

```bash
# Wait for specific text to appear (with timeout in ms)
tu wait --name test --text "EDITOR" --timeout 5000

# Chain: wait then act
tu wait --name test --text "ready" --timeout 5000 && tu type --name test "hello"

# Wait for LLM response (longer timeout)
tu wait --name test --text "AI:" --timeout 20000
```

## Example: Testing a TUI Editor

```bash
# Build
make editor.build

# Create test file
cat > /tmp/test-article.md << 'EOF'
---
title: Test Article
status: draft
---

Some content here.
EOF

# Launch
source ~/.secrets/env 2>/dev/null
tu run --name editor-test --size 120x40 \
  --env "GROQ_API_KEY=$GROQ_API_KEY" \
  -- ./target/release/devtui /tmp/test-article.md

# Wait for editor to load
tu wait --name editor-test --text "EDITOR" --timeout 5000

# Take screenshot to verify
tu screenshot --name editor-test | python3 -c "import sys,json; print(json.load(sys.stdin)['content'])"

# Open chat pane
tu press --name editor-test ctrl+y
tu wait --name editor-test --text "Ask" --timeout 3000

# Ask a question
tu type --name editor-test "what is this article about?"
tu press --name editor-test enter

# Wait for AI response
tu wait --name editor-test --text "AI:" --timeout 20000

# Screenshot to verify response
tu screenshot --name editor-test | python3 -c "import sys,json; print(json.load(sys.stdin)['content'])"

# Clean up
tu kill --name editor-test
```

## Example: Testing vim Keybindings

```bash
tu run --name vim-test --size 80x24 -- vim /tmp/test.txt

tu wait --name vim-test --text "~" --timeout 3000

# Enter insert mode and type
tu press --name vim-test i
tu type --name vim-test "Hello, world!"
tu press --name vim-test escape

# Save and quit
tu type --name vim-test ":wq"
tu press --name vim-test enter

# Verify file was written
cat /tmp/test.txt
```

## Tips

- **Always `tu wait` before interacting.** The app needs time to render.
- **Use `--timeout` generously.** LLM calls can take 10-20 seconds.
- **Kill sessions when done.** Leftover sessions consume resources.
- **Use `tu list`** to check for orphaned sessions.
- **Sleep is not allowed.** Use `tu wait --text` instead of `sleep`.
- **Split pane apps:** Parse specific columns from the screenshot to read each pane independently.
- **Debug with scrollback:** `tu scrollback --name <id>` shows the full buffer history, useful for finding text that scrolled off screen.
