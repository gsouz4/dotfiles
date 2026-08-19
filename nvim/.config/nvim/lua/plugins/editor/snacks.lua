-- ===================================================================
-- Snacks Picker Configuration - Modern Fuzzy Finder
-- ===================================================================
-- Comprehensive QoL plugin collection with modern fuzzy finder
-- Replaces telescope with enhanced features like frecency and git integration
-- See: https://github.com/folke/snacks.nvim

return {
  'folke/snacks.nvim',
  priority = 1000, -- Load early for better integration
  lazy = false, -- Don't lazy load for instant access
  dependencies = {
    -- Web dev icons (if Nerd Font is available)
    { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },
  },

  config = function()
    -- ===================================================================
    -- Snacks Setup and Configuration
    -- ===================================================================
    -- Snacks is a collection of QoL plugins for Neovim with modern
    -- fuzzy finding capabilities that enhance the development experience

    require('snacks').setup {
      -- ===================================================================
      -- Core Modules Configuration
      -- ===================================================================

      -- Modern fuzzy finder with frecency, git integration, and image previews
      picker = {
        enabled = true,

        -- Per-picker overrides live under `sources`, not `pickers`/`opts`.
        -- Snacks silently drops unknown keys, so a typo here means the whole
        -- block is dead config and every source falls back to its defaults.

        -- Fuzzy matching
        matcher = {
          frecency = true, -- rank recently/frequently opened files higher
        },

        sources = {
          files = {
            -- Stow packages keep everything under dot dirs (`nvim/.config/...`,
            -- `claude/.claude/...`). Without `hidden` the picker never descends
            -- into them and this repo looks like 8 files.
            hidden = true,
            ignored = false, -- still respect .gitignore
            exclude = {
              'node_modules',
              'target',
              'build',
              '*.o',
              '*.a',
              '*.out',
              '*.class',
              '*.pdf',
              '*.mkv',
              '*.mp4',
              '*.zip',
            },
          },

          grep = {
            -- Same reasoning as `files`: dot dirs hold the actual config.
            hidden = true,
            ignored = false,
            exclude = {
              'node_modules',
              'target',
              'build',
              '*.pdf',
              '*.mkv',
              '*.mp4',
              '*.zip',
            },
          },

          buffers = {
            sort_lastused = true,
          },
        },
      },

      -- ===================================================================
      -- Additional QoL Modules
      -- ===================================================================

      -- Enhanced notifications
      notifier = {
        enabled = true,
        timeout = 3000, -- 3 seconds
        style = 'compact',
      },

      -- Dashboard for startup screen
      dashboard = {
        enabled = false, -- Disabled by default, can be enabled later
      },

      -- Enhanced status column
      statuscolumn = {
        enabled = false, -- Keep existing statusline, can be enabled later
      },

      -- Better quickfile handling
      quickfile = {
        enabled = true,
      },

      -- Smooth scrolling
      scroll = {
        enabled = false,
        animate = {
          duration = { step = 15, total = 250 },
        },
      },

      -- Word highlighting
      words = {
        enabled = true,
      },

      -- Enhanced input dialogs
      input = {
        enabled = true,
      },

      -- Better indentation guides
      indent = {
        enabled = true,
        animate = {
          enabled = true,
        },
      },
    }

    -- ===================================================================
    -- Setup Keymaps
    -- ===================================================================
    -- Load keymaps from the keymaps module (cleaner separation)
    local keymaps = require 'config.keymaps'
    keymaps.setup_snacks_keymaps()

    -- ===================================================================
    -- Integration Notes
    -- ===================================================================
    -- Snacks picker provides all telescope functionality plus:
    -- - Built-in frecency (smart file ranking)
    -- - Native git integration (status, branches, logs)
    -- - Image previews directly in picker
    -- - Better performance and lower memory usage
    -- - Integrated QoL features (notifications, smooth scrolling)
    --
    -- Migration benefits:
    -- - Faster fuzzy finding with modern architecture
    -- - Smart file ranking based on usage patterns
    -- - Enhanced git workflow with built-in pickers
    -- - Image preview capabilities for better file browsing
    -- - Simplified configuration with better defaults
  end,
}
