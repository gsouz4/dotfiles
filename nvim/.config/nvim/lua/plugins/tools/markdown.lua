-- ===================================================================
-- Markdown Tools Configuration
-- ===================================================================
-- In-editor markdown rendering (float / tab / split / in-place toggle).
-- Renders real images & video inline via the Kitty graphics protocol,
-- which Ghostty supports. No external browser required.
-- See: https://github.com/delphinus/md-render.nvim
--
-- Requires Neovim >= 0.12. On machines still on the apt 0.11.x build the
-- `cond` gate below makes lazy.nvim silently skip the plugin.

return {
  {
    'delphinus/md-render.nvim',
    version = '*',

    -- Skip entirely on Neovim < 0.12 (e.g. distro/apt builds).
    cond = function()
      return vim.fn.has 'nvim-0.12' == 1
    end,

    dependencies = {
      { 'nvim-tree/nvim-web-devicons', version = '*' },
      { 'delphinus/budoux.lua', version = '*' },
    },

    -- Lazy calls require('md-render').setup(opts).
    opts = {},

    -- Keymaps live here (not in a FileType autocmd) so lazy.nvim registers
    -- them up-front: they load the plugin on demand and are picked up by
    -- which-key immediately. Leader = ";".
    keys = {
      { '<leader>mp', '<Plug>(md-render-preview)', desc = '[M]arkdown [P]review (float)' },
      { '<leader>ms', '<cmd>MdRender split<CR>', desc = '[M]arkdown [S]plit (side-by-side)' },
      { '<leader>mt', '<Plug>(md-render-preview-tab)', desc = '[M]arkdown [T]ab preview' },
      { '<leader>mr', '<Plug>(md-render-toggle)', desc = '[M]arkdown [R]ender in-place' },
      { '<leader>ma', '<Plug>(md-render-auto)', desc = '[M]arkdown [A]uto toggle' },
      { '<leader>md', '<Plug>(md-render-demo)', desc = '[M]arkdown [D]emo' },
    },
  },
}
