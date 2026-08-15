-- ===================================================================
-- Database Client - nvim-dbee
-- ===================================================================
-- Interactive database client: connection drawer, SQL scratchpads and a
-- paginated result view.
--
-- It talks to the database over the native wire protocol through a Go
-- backend, so no `psql` / `mysql` CLI is required on the machine.
-- See: https://github.com/kndndrj/nvim-dbee

-- ===================================================================
-- Compatibility Shim - BufModifiedSet
-- ===================================================================
-- The drawer registers a `BufModifiedSet` autocmd to draw the "unsaved"
-- dot next to scratchpads. Neovim 0.13 removed that event (`:help
-- deprecated` -> use `OptionSet` with pattern "modified"), so every
-- drawer refresh throws and the UI never opens.
--
-- Upstream has had no commits since 2025-07, so translate the event here
-- instead of waiting for a fix. Only the exact removed event is rewritten;
-- everything else goes straight through, and the shim disappears on its
-- own if a future Neovim brings the event back.
local function compat_buf_modified_set()
  if pcall(vim.api.nvim_get_autocmds, { event = 'BufModifiedSet' }) then
    return
  end

  local create_autocmd = vim.api.nvim_create_autocmd

  vim.api.nvim_create_autocmd = function(events, opts)
    if type(events) == 'table' and #events == 1 and events[1] == 'BufModifiedSet' then
      -- `OptionSet` matches on the option name, so the buffer filter has
      -- to move from the autocmd into the callback - otherwise this fires
      -- for every buffer in the session instead of the one dbee asked for.
      local buffer, callback = opts.buffer, opts.callback

      local translated = vim.tbl_extend('force', {}, opts)
      translated.buffer = nil
      translated.pattern = 'modified'
      translated.callback = function(event)
        if buffer and event.buf ~= buffer then
          return
        end
        return callback(event)
      end

      return create_autocmd({ 'OptionSet' }, translated)
    end

    return create_autocmd(events, opts)
  end
end

-- ===================================================================
-- Call Log - start every session clean
-- ===================================================================
-- The backend keeps the call log across restarts in two hardcoded paths:
-- the list of executed queries in /tmp/dbee-calllog.json, and each result
-- in /tmp/dbee-history/<call-id>/. It restores them when it starts and
-- rewrites them when Neovim quits, so the panel grows forever and every
-- query sits in /tmp in plain text, world readable.
--
-- There is no UI action and no API to clear it, and deleting the files from
-- a VimLeavePre autocmd loses the race - the backend writes them again on
-- its way out. So the purge happens here, before the backend comes up: the
-- log covers the current session and nothing older. Drop this call to keep
-- the history.
local CALL_LOG = '/tmp/dbee-calllog.json'
local CALL_HISTORY = '/tmp/dbee-history'

-- Both paths are shared by every Neovim on the machine, so opening dbee in
-- a second instance drops the archives of the first: its panel keeps
-- listing the older calls, but <CR> can no longer bring their results back.
-- New queries archive normally.
local function purge_call_log()
  vim.fn.delete(CALL_LOG)
  vim.fn.delete(CALL_HISTORY, 'rf')
end

return {
  'kndndrj/nvim-dbee',

  -- UI primitives (popups, splits) - already vendored by neo-tree
  dependencies = { 'MunifTanjim/nui.nvim' },

  -- ===================================================================
  -- Lazy Loading
  -- ===================================================================
  -- Nothing is needed until a database is actually opened
  cmd = 'Dbee',
  keys = {
    { '<leader>db', '<cmd>Dbee toggle<cr>', desc = 'Toggle [D]ata[B]ase UI' },
  },

  -- ===================================================================
  -- Backend Build
  -- ===================================================================
  -- Builds the Go backend on install and on every update.
  --
  -- Left to itself the installer downloads a prebuilt binary pinned to a
  -- 2024 commit, a year behind the Lua that ships in master. Building from
  -- source keeps the two halves in sync; `go` comes from mise, so this
  -- works on any machine that has the repo's `.tool-versions` installed.
  build = function()
    require('dbee').install 'go'
  end,

  config = function()
    compat_buf_modified_set()
    purge_call_log()

    -- Defaults are good. Connections come from two built-in sources:
    --
    --   1. $DBEE_CONNECTIONS - a JSON array, e.g. exported from
    --      ~/.secrets/env so credentials never touch this repo:
    --        export DBEE_CONNECTIONS='[{"name":"app","type":"postgres","url":"postgres://..."}]'
    --
    --   2. ~/.local/state/nvim/dbee/persistence.json - written by the
    --      drawer itself when a connection is added with `cw`. Outside
    --      the repo, so it is never committed either.
    require('dbee').setup()
  end,
}
