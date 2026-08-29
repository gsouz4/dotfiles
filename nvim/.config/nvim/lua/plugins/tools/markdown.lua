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
      -- Keep the preview alive when switching buffers: the herdr pane below
      -- outlives buffer changes, so auto-close would just leave it stale.
      vim.g.mkdp_auto_close = 0

      -- Route the preview into a herdr pane running terminal-browser, so the
      -- GitHub-style render sits side by side with the buffer instead of in a
      -- separate OS window. Falls back to the default browser when nvim is
      -- not inside herdr or terminal-browser is missing (other machines, ssh).
      vim.g.mkdp_browserfunc = 'MkdpOpenPreview'

      -- Lifecycle: the mkdp server dies with nvim (it is a child job), the
      -- terminal-browser process dies with its pane, and the pane is closed
      -- here — on replace, on toggle-off, and on nvim exit — so nothing is
      -- left orphaned eating a Chromium's worth of memory.
      local preview_pane

      local function close_pane(wait)
        if not preview_pane then
          return
        end
        local proc = vim.system { 'herdr', 'pane', 'close', preview_pane }
        if wait then
          proc:wait(2000)
        end
        preview_pane = nil
      end

      _G.MkdpOpenPreview = function(url)
        if not (vim.env.HERDR_PANE_ID and vim.fn.executable 'terminal-browser' == 1) then
          vim.ui.open(url)
          return
        end
        close_pane(true)
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

      -- Toggle that also tears the pane down. :MarkdownPreviewToggle alone
      -- would stop the server but leave the pane showing a dead page.
      _G.MkdpTogglePreview = function()
        if preview_pane then
          pcall(vim.cmd, 'MarkdownPreviewStop')
          close_pane(false)
        else
          vim.cmd 'MarkdownPreview'
        end
      end

      vim.api.nvim_create_autocmd('VimLeavePre', {
        group = vim.api.nvim_create_augroup('mkdp-herdr-cleanup', { clear = true }),
        callback = function()
          close_pane(true)
        end,
      })
    end,
    keys = {
      {
        '<leader>mg',
        function()
          _G.MkdpTogglePreview()
        end,
        desc = '[M]arkdown [G]itHub-style preview',
      },
    },
  },
}
