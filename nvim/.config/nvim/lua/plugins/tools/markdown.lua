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

  -- =================================================================
  -- GitHub-style live preview (real HTML in the browser)
  -- =================================================================
  -- md-render above draws inside terminal cells; this one serves the
  -- buffer over a local server and opens it in the default browser with
  -- GitHub CSS, live refresh on every keystroke, and scroll sync.
  -- The build step downloads a prebuilt server bundle (needs node, which
  -- comes from mise).
  {
    'iamcco/markdown-preview.nvim',
    cmd = { 'MarkdownPreviewToggle', 'MarkdownPreview', 'MarkdownPreviewStop' },
    ft = { 'markdown' },
    -- The plugin is lazy-loaded, so its autoload funcs are not on the rtp
    -- when the build task runs; load it first (lazy.nvim FAQ workaround).
    build = function()
      require('lazy').load { plugins = { 'markdown-preview.nvim' } }
      vim.fn['mkdp#util#install']()
    end,
    init = function()
      vim.g.mkdp_theme = 'dark' -- GitHub dark; 'light' also available
      vim.g.mkdp_auto_close = 1 -- close the tab when leaving the buffer

      -- Route the preview into a herdr pane running terminal-browser, so the
      -- GitHub-style render sits side by side with the buffer instead of in a
      -- separate OS window. Falls back to the default browser when nvim is
      -- not inside herdr or terminal-browser is missing (other machines, ssh).
      vim.g.mkdp_browserfunc = 'MkdpOpenPreview'

      local preview_pane -- reuse/replace the pane across preview toggles
      _G.MkdpOpenPreview = function(url)
        if not (vim.env.HERDR_PANE_ID and vim.fn.executable 'terminal-browser' == 1) then
          vim.ui.open(url)
          return
        end
        if preview_pane then
          vim.system({ 'herdr', 'pane', 'close', preview_pane }):wait()
          preview_pane = nil
        end
        local split = vim.system({ 'herdr', 'pane', 'split', '--current', '--direction', 'right', '--no-focus' }, { text = true }):wait()
        local ok, res = pcall(vim.json.decode, split.stdout or '')
        local pane = ok and res.result and res.result.pane and res.result.pane.pane_id or nil
        if not pane then
          vim.notify('herdr pane split failed; opening in browser', vim.log.levels.WARN)
          vim.ui.open(url)
          return
        end
        preview_pane = pane
        vim.system { 'herdr', 'pane', 'run', pane, 'terminal-browser', 'open', url }
      end
      vim.cmd [[
        function! MkdpOpenPreview(url) abort
          call v:lua.MkdpOpenPreview(a:url)
        endfunction
      ]]
    end,
    keys = {
      { '<leader>mg', '<cmd>MarkdownPreviewToggle<CR>', desc = '[M]arkdown [G]itHub-style preview' },
    },
  },
}
