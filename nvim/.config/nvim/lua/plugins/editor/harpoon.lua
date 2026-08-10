-- ===================================================================
-- Harpoon - Pinned File Slots
-- ===================================================================
-- Curated, per-project list of files reachable by a fixed key. Unlike the
-- snacks pickers (<C-p> files, ;<space> buffers), the list never reorders
-- itself: ;1 means the same file today and tomorrow, no typing, no list.
-- See: https://github.com/ThePrimeagen/harpoon/tree/harpoon2
--
-- Usage:
--  - ;a      - [A]dd the current file to the end of the list
--  - ;e      - Toggle the quick m[e]nu (edit as a normal buffer: dd to
--              remove a line, reorder lines, :w to save the new list)
--  - ;1..;4  - Jump straight to slot 1-4
--  - [h / ]h - Cycle to the previous/next entry

return {
  'ThePrimeagen/harpoon',
  branch = 'harpoon2',
  dependencies = { 'nvim-lua/plenary.nvim' },

  -- Lazy-load on first use of any keymap below
  keys = {
    {
      '<leader>a',
      function()
        require('harpoon'):list():add()
      end,
      desc = 'Harpoon [a]dd file',
    },
    {
      '<leader>e',
      function()
        local harpoon = require 'harpoon'
        harpoon.ui:toggle_quick_menu(harpoon:list())
      end,
      desc = 'Harpoon quick m[e]nu',
    },

    -- Fixed slots. The whole point: muscle memory, not search.
    {
      '<leader>1',
      function()
        require('harpoon'):list():select(1)
      end,
      desc = 'Harpoon file 1',
    },
    {
      '<leader>2',
      function()
        require('harpoon'):list():select(2)
      end,
      desc = 'Harpoon file 2',
    },
    {
      '<leader>3',
      function()
        require('harpoon'):list():select(3)
      end,
      desc = 'Harpoon file 3',
    },
    {
      '<leader>4',
      function()
        require('harpoon'):list():select(4)
      end,
      desc = 'Harpoon file 4',
    },

    -- Sequential navigation, for when you don't remember the slot number.
    -- ]c/[c are gitsigns hunks, so harpoon takes the `h` pair.
    {
      '[h',
      function()
        require('harpoon'):list():prev()
      end,
      desc = 'Harpoon previous file',
    },
    {
      ']h',
      function()
        require('harpoon'):list():next()
      end,
      desc = 'Harpoon next file',
    },
  },

  config = function()
    require('harpoon').setup {
      settings = {
        -- Persist the list per project root so ;1 survives a restart
        save_on_toggle = true,
        sync_on_ui_close = true,
        key = function()
          return vim.uv.cwd()
        end,
      },
    }
  end,
}
