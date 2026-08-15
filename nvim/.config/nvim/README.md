# Neovim Config

Modular configuration built on [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim). Lua only, managed by [lazy.nvim](https://github.com/folke/lazy.nvim).

## Quick start

```bash
# From the dotfiles repo
make stow-nvim

# Or manually
ln -s ~/Documents/code/dotfiles/nvim/.config/nvim ~/.config/nvim
nvim --headless +'Lazy install' +qall
```

## Structure

```
init.lua                    Entry point
lua/
  config/
    options.lua             Leader = ;, line numbers, search, splits
    keymaps.lua             All bindings + LSP/snacks/inlay hint helpers
    autocmds.lua            Yank highlight, neo-tree auto-quit, LSP lifecycle
    lazy.lua                Plugin manager bootstrap
  plugins/
    ui/                     Everforest theme, lualine, which-key, todo-comments
    editor/                 Snacks (fuzzy finder), treesitter, mini.nvim
    coding/                 LSP, completion, formatting
    tools/                  Copilot, diffview, languages, markdown, sleuth
  kickstart/                Health check, DAP, gitsigns, indent, lint, neo-tree, autopairs
  tests/                    Plenary specs
tests/run.lua               Test runner
Makefile                    Dev commands
```

## Keymaps

Leader is `;` (semicolon).

### Files and search

| Key | Action |
|-----|--------|
| `Ctrl-p` / `;sf` / `<Space>ff` / `<Space>pp` | Find files (frecency) |
| `Ctrl-f` / `;sg` | Live grep |
| `Ctrl-i` / `;s.` | Recent files |
| `;;` | Open buffers |
| `;s/` | Search in open files |
| `;sn` | Search nvim config |
| `;sh` | Help tags |
| `;sk` | Keymaps |
| `;sd` | Diagnostics |
| `;/` | Current buffer search |
| `;sr` | Resume last search |

### Navigation

| Key | Action |
|-----|--------|
| `;n` | Toggle neo-tree |
| `;k` | Reveal current file in tree |
| `Ctrl-h/j/k/l` | Window navigation |

### LSP

| Key | Action |
|-----|--------|
| `gd` | Go to definition |
| `gr` | Go to references |
| `gI` | Go to implementation |
| `K` | Hover documentation |
| `;rn` | Rename symbol |
| `;ca` | Code actions |
| `;th` | Toggle inlay hints |
| `;f` | Format buffer |

### Git

| Key | Action |
|-----|--------|
| `;gb` | Git branches |
| `;gc` | Git commits |
| `;gs` | Git status |
| `;gd` | Diffview - all changes (toggle) |
| `;gh` | Diffview - current file history |
| `;gH` | Diffview - repo history |
| `;hs` | Stage hunk |
| `;hr` | Reset hunk |
| `;hp` | Preview hunk |
| `;hb` | Blame line |
| `]c` / `[c` | Next/prev hunk |

### Debug (DAP)

| Key | Action |
|-----|--------|
| `F5` | Start/Continue |
| `F1` | Step into |
| `F2` | Step over |
| `F3` | Step out |
| `F7` | Toggle debug UI |
| `;b` | Toggle breakpoint |

### Other

| Key | Action |
|-----|--------|
| `;tt` | Toggle dark/light theme |
| `;mp` | Markdown preview (browser) |
| `;mg` | Markdown glow (terminal) |
| `;cz` | Copy file path to clipboard |
| `;db` | Toggle database UI (see [Database](#database)) |

## LSP servers

Managed by Mason. Auto-installed:

- **rust_analyzer** - Clippy on save, all cargo features, proc macros, inlay hints
- **lua_ls** - Neovim Lua with LazyDev integration
- **golangci_lint_ls** - Go diagnostics only, no navigation

Not from Mason:

- **gopls** - staticcheck, gofumpt, unusedparams/shadow analyses, inlay hints. The binary is managed by mise (`.tool-versions`), so Mason's `automatic_enable` never sees it and `lsp.lua` enables it explicitly.

Servers are registered via `vim.lsp.config()`. mason-lspconfig v2 dropped the `handlers` option — if it comes back, it is ignored silently and every per-server setting stops applying.

## Formatters

Via conform.nvim. Format on save enabled (toggle with `:FormatToggle`).

| Language | Formatter |
|----------|-----------|
| Lua | stylua |
| JS/TS/JSON | prettier |
| Python | black + isort |
| Rust | rustfmt |
| Go | gofmt |
| C/C++ | clang-format |
| Shell | shfmt |

## Linters

Via nvim-lint. Auto-lint on BufEnter, BufWritePost, InsertLeave.

- Markdown: markdownlint

## Database

nvim-dbee (`;db`). Drawer with connections and scratchpads on the left, SQL editor on the right, paginated result view below. The Go backend speaks the wire protocol directly, so no `psql`/`mysql` client is needed.

| Key | Where | Action |
|-----|-------|--------|
| `;db` | anywhere | Toggle the UI |
| `BB` | editor | Run the whole buffer (or the selection, in visual) |
| `<CR>` | editor | Run the line under the cursor |
| `<CR>` / `o` | drawer | Select connection / expand node |
| `cw` / `dd` | drawer | Edit / delete connection or scratchpad |
| `L` / `H` | result | Next / previous page (100 rows) |
| `E` / `F` | result | Last / first page |
| `yaj` / `yac` | result | Yank row as JSON / CSV (`yaJ` / `yaC` for all rows) |

Connections come from two sources, both outside this repo:

- `$DBEE_CONNECTIONS` — a JSON array, exported from `~/.secrets/env`:
  ```bash
  export DBEE_CONNECTIONS='[{"name":"app","type":"postgres","url":"postgres://user:pass@localhost:5432/app"}]'
  ```
- `~/.local/state/nvim/dbee/persistence.json` — the saved-connections file, written by the drawer when a connection is added with `add` / `cw`. This is the DBeaver equivalent: add once, it is there forever.

Every field of a connection goes through a Go template before dbee connects, so a saved connection does not have to hold the password:

```json
[
  {
    "id": "local_pg",
    "name": "local pg",
    "type": "postgres",
    "url": "postgres://postgres:{{ exec `pass db/local-pg` }}@localhost:5432/postgres?sslmode=disable"
  }
]
```

`{{ env `VAR` }}` and `{{ exec `command` }}` are the two functions available (`exec` accepts a pipe). Hand-written entries **need the `id` field** — without it the connection is skipped silently, no error. Lines starting with `//` are allowed as comments.

### Migrating from DBeaver

`dbeaver-to-dbee` (in the `local-bin` package) reads DBeaver's `data-sources.json`, decrypts `credentials-config.json`, and prints the equivalent dbee source:

```bash
dbeaver-to-dbee                                       # find the workspace, print to stdout
dbeaver-to-dbee --password-command 'pass db/{slug}'   # keep passwords in pass
dbeaver-to-dbee --with-passwords -o ~/.local/state/nvim/dbee/persistence.json
```

By default passwords are left out, replaced by `{{ env `DBEE_PW_<NAME>` }}` placeholders. Providers with no dbee adapter are reported and skipped.

### Call log

The panel at the bottom left lists every query run against the selected connection — `<CR>` brings a past result back without re-executing, `<C-c>` cancels one still running.

The backend persists it in two hardcoded paths: `/tmp/dbee-calllog.json` (the list) and `/tmp/dbee-history/<call-id>/` (each result, as gob files). It restores them on startup and rewrites them when Neovim quits, so by default the log grows across sessions and every query sits in `/tmp` in plain text, readable by any user on the machine.

There is no way to clear it from the UI — the call log has exactly two actions and the API has no delete. `database.lua` therefore wipes both paths at startup, before the backend comes up, so the panel only ever shows the current session. Deleting them from a `VimLeavePre` autocmd would not work: the backend writes them again on its way out.

Consequence worth knowing: those paths are shared by every Neovim on the machine, so opening dbee in a second instance drops the first one's archives. Its panel keeps listing the older calls, but `<CR>` can no longer bring their results back.

Two rough edges worth knowing:

- The backend binary is built from source by the `build` step (`require('dbee').install()`), which needs `go` on PATH — it comes from mise. The prebuilt binary the installer prefers is a year older than the plugin's Lua, so the spec forces the source build.
- `:qa` with the UI open only closes dbee's windows; a second `:qa` quits. Toggle the UI off with `;db` first and one `:qa` is enough.

Upstream has had no commits since 2025-07, so `database.lua` carries a shim for the `BufModifiedSet` event that Neovim 0.13 removed. Without it the drawer throws on every refresh and the UI never opens.

## Dev commands

```bash
make test           # Run test suite (plenary)
make health         # Neovim health check
make format         # Format lua/ with stylua
make lint           # Check lua style
make sync           # Sync plugins + Mason tools
make startup-time   # Measure startup time
make doctor         # health + test
```

## CI

GitHub Actions workflow at `.github/workflows/ci.yml`. Runs on `nvim/**` changes:

1. Install neovim + stylua + plugins (all cached)
2. `stylua --check lua/`
3. `make health`
4. `make test`

## Theme

Everforest with medium contrast. Toggle dark/light with `;tt`.

## Customization

### Add a language server

Edit `lua/plugins/coding/lsp.lua`, add to the `servers` table:

```lua
pyright = {},
ts_ls = {},
clangd = {},
```

Mason installs them on next startup and `automatic_enable` starts them.

If the binary is managed outside Mason (mise, cargo, a system package), also filter it out of `ensure_installed` and call `vim.lsp.enable '<name>'` yourself — see how `gopls` is handled.

### Add a formatter

Edit `lua/plugins/coding/formatting.lua`:

```lua
formatters_by_ft = {
  -- existing...
  your_language = { "your_formatter" },
}
```

### Add a plugin

Create a file in the appropriate `lua/plugins/` directory:

```lua
-- lua/plugins/tools/your-plugin.lua
return {
  'author/your-plugin',
  config = function()
    -- setup here
  end,
}
```

## Commands

```vim
:Lazy                 " Plugin manager UI
:Lazy sync            " Update all plugins
:Mason                " Manage LSP servers and tools
:LspInfo              " Show active LSP clients
:LspRestart           " Restart LSP
:ConformInfo          " Show formatter info
:FormatToggle         " Toggle format-on-save
:checkhealth          " System diagnostics
```

## Troubleshooting

**Plugins not loading**: `:Lazy sync` then restart nvim.

**LSP not working**: `:LspInfo` to check status, `:Mason` to verify server is installed.

**Slow startup**: `make startup-time` to find bottlenecks.

**Nuclear reset** (re-downloads everything):

```bash
rm -rf ~/.local/share/nvim ~/.local/state/nvim ~/.cache/nvim
nvim
```

## Dependencies

- Neovim 0.10+
- git, make, unzip, gcc, ripgrep
- Nerd Font (for icons)
- Node.js (for some Mason tools)
