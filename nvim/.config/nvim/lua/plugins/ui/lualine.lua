-- ===================================================================
-- Lualine Status Line Configuration
-- ===================================================================
-- Beautiful and informative status line that integrates with our theme
-- See: https://github.com/nvim-lualine/lualine.nvim

-- O terminal do claudecode.nvim tem nome `term://<cwd>//<pid>:<caminho do
-- executável>`. Só na statusline, troca isso por "Claude". O bufnr vem do
-- plugin; `package.loaded` evita carregar o claudecode só pra desenhar a barra.
local function claude_name(str)
  local term = package.loaded['claudecode.terminal']
  if term and term.get_active_terminal_bufnr() == vim.api.nvim_get_current_buf() then
    return 'Claude'
  end
  return str
end

return {
  'nvim-lualine/lualine.nvim',
  event = 'VeryLazy', -- Load after initial startup for better performance
  dependencies = {
    -- Web dev icons for file types and git status
    { 'nvim-tree/nvim-web-devicons', opt = true },
  },

  opts = {
    options = {
      -- Use everforest theme to match our colorscheme
      theme = 'everforest',

      -- Enable icons if Nerd Font is available
      icons_enabled = vim.g.have_nerd_font,

      -- Separator style - clean and minimal
      section_separators = { '', '' }, -- No separators for cleaner look
      component_separators = { '', '' }, -- No component separators

      -- Global status line (single status line for all windows)
      globalstatus = true,

      -- Don't show status line in certain file types
      disabled_filetypes = {
        statusline = { 'neo-tree' }, -- Hide in file explorer
        winbar = {},
      },
    },

    sections = {
      -- Left side: mode, git branch, file info
      lualine_a = { 'mode' },
      lualine_b = {
        'branch',
        'diff',
        {
          'diagnostics',
          -- Only show error and warning counts to keep it clean
          sources = { 'nvim_diagnostic' },
          sections = { 'error', 'warn' },
          symbols = { error = ' ', warn = ' ', info = ' ', hint = ' ' },
          colored = true,
        },
      },
      lualine_c = {
        {
          'filename',
          -- Show relative path and modified status
          path = 1, -- 0 = filename, 1 = relative path, 2 = absolute path
          fmt = claude_name,
          symbols = {
            modified = '●', -- Text to show when the buffer is modified
            readonly = '', -- Text to show when the buffer is readonly
            unnamed = '[No Name]', -- Text to show for unnamed buffers
          },
        },
      },

      -- Right side: LSP status, file info, position
      lualine_x = {
        {
          -- Show attached LSP servers
          function()
            local clients = vim.lsp.get_clients { bufnr = 0 }
            if #clients == 0 then
              return ''
            end

            local names = {}
            for _, client in ipairs(clients) do
              table.insert(names, client.name)
            end
            return ' ' .. table.concat(names, ', ')
          end,
          color = { gui = 'italic' },
        },
        'encoding',
        'fileformat',
        'filetype',
      },
      lualine_y = { 'progress' },
      lualine_z = {
        {
          'location',
          -- Show line:column
          fmt = function(str)
            return str:gsub('%%l:%%c', '%l:%c')
          end,
        },
      },
    },

    inactive_sections = {
      -- Minimal info for inactive windows
      lualine_a = {},
      lualine_b = {},
      lualine_c = {
        {
          'filename',
          path = 1,
          fmt = claude_name,
        },
      },
      lualine_x = { 'location' },
      lualine_y = {},
      lualine_z = {},
    },

    tabline = {},
    winbar = {},
    inactive_winbar = {},

    extensions = {
      -- Enable extensions for better integration
      'neo-tree',
      'lazy',
      'mason',
      'fugitive', -- Git integration
    },
  },
}
