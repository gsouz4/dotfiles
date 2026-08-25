-- ===================================================================
-- Treesitter Configuration (nvim-treesitter `main` branch)
-- ===================================================================
-- Advanced syntax highlighting, text objects, and code understanding.
-- The `main` branch is a full rewrite that delegates highlight/fold/indent to
-- Neovim core and installs parsers via `require('nvim-treesitter').install`.
-- Requires Neovim >= 0.12 and the tree-sitter CLI (managed by mise).
-- See: https://github.com/nvim-treesitter/nvim-treesitter/tree/main

return {
  'nvim-treesitter/nvim-treesitter',
  branch = 'main',
  build = ':TSUpdate', -- Update installed parsers when the plugin updates
  event = { 'BufReadPre', 'BufNewFile' }, -- Load when opening files
  dependencies = {
    -- Text objects moved to a separate plugin (also rewritten for `main`)
    { 'nvim-treesitter/nvim-treesitter-textobjects', branch = 'main' },
  },

  config = function()
    local ts = require 'nvim-treesitter'

    -- Install parsers into stdpath('data')/site (prepended to runtimepath)
    ts.setup {}

    -- ===================================================================
    -- Parser Installation
    -- ===================================================================
    -- Languages to ensure are installed (installs asynchronously; no-op if
    -- already present). `:TSUpdate` (build step) performs the first sync.
    local ensure_installed = {
      -- Core languages for Neovim configuration
      'lua',
      'luadoc',
      'vim',
      'vimdoc',
      'query',

      -- System and shell
      'bash',

      -- Web development
      'html',
      'css',
      'javascript',
      'typescript',
      'tsx',
      'json',

      -- Systems programming
      'c',
      'rust',
      'go',

      -- Elixir
      'elixir',
      'heex',
      'eex',

      -- Markup and data
      'markdown',
      'markdown_inline',
      'toml',
      'yaml',

      -- Git and diffs
      'diff',
      'git_config',
      'git_rebase',
      'gitcommit',
      'gitignore',

      -- Documentation
      'comment',
    }

    local installed = ts.get_installed()
    local to_install = vim.tbl_filter(function(lang)
      return not vim.tbl_contains(installed, lang)
    end, ensure_installed)
    if #to_install > 0 then
      ts.install(to_install)
    end

    -- ===================================================================
    -- Highlighting, Folding, Indentation (per-buffer, via Neovim core)
    -- ===================================================================
    -- Languages that misbehave with treesitter indentation.
    local indent_disable = { ruby = true, python = true }

    vim.api.nvim_create_autocmd('FileType', {
      desc = 'Enable treesitter highlight/fold/indent for supported filetypes',
      group = vim.api.nvim_create_augroup('nvim-treesitter-start', { clear = true }),
      callback = function(ev)
        local buf = ev.buf
        local lang = vim.treesitter.language.get_lang(ev.match) or ev.match

        -- Disable treesitter for very large files (performance)
        local ok, stats = pcall((vim.uv or vim.loop).fs_stat, vim.api.nvim_buf_get_name(buf))
        if ok and stats and stats.size > 100 * 1024 then
          return
        end

        -- Start highlighting. pcall guards the case where the parser is not
        -- (yet) installed, so a missing parser degrades gracefully instead of
        -- throwing (the failure mode that broke opening files before).
        if not pcall(vim.treesitter.start, buf, lang) then
          return
        end

        -- Treesitter-based folding (window-local)
        vim.wo[0][0].foldexpr = 'v:lua.vim.treesitter.foldexpr()'

        -- Treesitter-based indentation
        if not indent_disable[lang] then
          vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
      end,
    })

    -- Global fold options (don't fold by default)
    vim.opt.foldmethod = 'expr'
    vim.opt.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
    vim.opt.foldenable = false
    vim.opt.foldlevel = 99

    -- ===================================================================
    -- Text Objects (nvim-treesitter-textobjects `main`)
    -- ===================================================================
    require('nvim-treesitter-textobjects').setup {
      select = {
        lookahead = true, -- jump forward to the textobj, like targets.vim
      },
      move = {
        set_jumps = true, -- store movements in the jumplist
      },
    }

    local select = require 'nvim-treesitter-textobjects.select'
    local move = require 'nvim-treesitter-textobjects.move'

    -- Selection text objects (visual + operator-pending)
    local select_maps = {
      ['aa'] = '@parameter.outer',
      ['ia'] = '@parameter.inner',
      ['af'] = '@function.outer',
      ['if'] = '@function.inner',
      ['ac'] = '@class.outer',
      ['ic'] = '@class.inner',
      ['al'] = '@loop.outer',
      ['il'] = '@loop.inner',
      ['ab'] = '@block.outer',
      ['ib'] = '@block.inner',
      ['a/'] = '@comment.outer',
      ['i/'] = '@comment.inner',
    }
    for lhs, query in pairs(select_maps) do
      vim.keymap.set({ 'x', 'o' }, lhs, function()
        select.select_textobject(query, 'textobjects')
      end, { desc = 'TS select ' .. query })
    end

    -- Movement between text objects (normal + visual + operator-pending)
    local move_maps = {
      goto_next_start = { [']m'] = '@function.outer', [']]'] = '@class.outer', [']l'] = '@loop.outer' },
      goto_next_end = { [']M'] = '@function.outer', [']['] = '@class.outer', [']L'] = '@loop.outer' },
      goto_previous_start = { ['[m'] = '@function.outer', ['[['] = '@class.outer', ['[l'] = '@loop.outer' },
      goto_previous_end = { ['[M'] = '@function.outer', ['[]'] = '@class.outer', ['[L'] = '@loop.outer' },
    }
    for fn, maps in pairs(move_maps) do
      for lhs, query in pairs(maps) do
        vim.keymap.set({ 'n', 'x', 'o' }, lhs, function()
          move[fn](query, 'textobjects')
        end, { desc = 'TS ' .. fn .. ' ' .. query })
      end
    end

    -- ===================================================================
    -- Incremental Selection (manual reimplementation)
    -- ===================================================================
    local incr = require 'config.ts-incremental'
    vim.keymap.set('n', '<C-space>', incr.init, { desc = 'TS init selection' })
    vim.keymap.set('x', '<C-space>', incr.increment, { desc = 'TS grow selection' })
    vim.keymap.set('x', '<C-s>', incr.increment, { desc = 'TS grow selection (scope)' })
    vim.keymap.set('x', '<M-space>', incr.decrement, { desc = 'TS shrink selection' })
  end,
}
