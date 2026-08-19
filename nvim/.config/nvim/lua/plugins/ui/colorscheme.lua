-- ===================================================================
-- Colorscheme Configuration
-- ===================================================================
-- Default: Catppuccin (mocha). Everforest is kept installed as a secondary
-- theme. Switch between them at runtime with the picker below:
--   :ColorschemePick   or   <leader>tc   or   :lua SwitchColorscheme()
-- Toggle dark/light for the active theme with <leader>tt (see keymaps.lua).

-- Themes offered by the switcher. Each entry sets the colorscheme and the
-- matching 'background' so light/dark-aware plugins stay consistent.
local themes = {
  { label = "Catppuccin Mocha (dark)", scheme = "catppuccin-mocha", background = "dark" },
  { label = "Catppuccin Macchiato (dark)", scheme = "catppuccin-macchiato", background = "dark" },
  { label = "Catppuccin Frappé (dark)", scheme = "catppuccin-frappe", background = "dark" },
  { label = "Catppuccin Latte (light)", scheme = "catppuccin-latte", background = "light" },
  { label = "Everforest (dark)", scheme = "everforest", background = "dark" },
  { label = "Everforest (light)", scheme = "everforest", background = "light" },
  { label = "Gruvbox (dark)", scheme = "gruvbox", background = "dark" },
  { label = "Rose Pine", scheme = "rose-pine-moon", background = "dark" },
}

local function apply_theme(theme)
  vim.o.background = theme.background
  vim.cmd.colorscheme(theme.scheme)
end

-- Global so it can be called from anywhere: `:lua SwitchColorscheme()`.
-- Opens a picker (rendered by snacks via vim.ui.select) to choose a theme.
function SwitchColorscheme()
  vim.ui.select(themes, {
    prompt = "Select colorscheme:",
    format_item = function(item)
      return item.label
    end,
  }, function(choice)
    if choice then
      apply_theme(choice)
      vim.notify("Colorscheme: " .. choice.label, vim.log.levels.INFO)
    end
  end)
end

return {
  -- =================================================================
  -- Catppuccin — default theme
  -- https://github.com/catppuccin/nvim
  -- =================================================================
  {
    "catppuccin/nvim",
    name = "catppuccin", -- repo is catppuccin/nvim; name avoids a 'nvim' clash
    lazy = false,
    priority = 1000, -- load before other UI plugins

    config = function()
      require("catppuccin").setup {
        flavour = "mocha", -- default flavour
        -- Flavour follows 'background' when applied via the generic
        -- `catppuccin` scheme, so <leader>tt swaps latte <-> mocha.
        background = { light = "latte", dark = "mocha" },
        transparent_background = false,
        integrations = {
          treesitter = true,
          native_lsp = { enabled = true },
          gitsigns = true,
          which_key = true,
          mini = { enabled = true },
          snacks = { enabled = true },
          markdown = true,
        },
      }

      -- Apply as the default colorscheme.
      -- vim.o.background = 'dark'
      -- vim.cmd.colorscheme 'catppuccin-frappe'

      -- Expose the switcher via a command and a keymap.
      vim.api.nvim_create_user_command("ColorschemePick", SwitchColorscheme, { desc = "Pick a colorscheme" })
      vim.keymap.set("n", "<leader>tc", SwitchColorscheme, { desc = "Toggle [T]heme — [C]olorscheme picker" })
    end,
  },

  -- =================================================================
  -- Everforest — secondary theme (selectable via the switcher)
  -- https://github.com/neanias/everforest-nvim
  -- =================================================================
  {
    "neanias/everforest-nvim",
    name = "everforest",
    lazy = false,
    priority = 900, -- loads after catppuccin; only registers, does not apply

    config = function()
      require("everforest").setup {
        background = "medium", -- 'soft' | 'medium' | 'hard'
        transparent_background_level = 0,
        italics = true,
        disable_terminal_colors = false,
        ui_contrast = "low", -- 'low' | 'high'
        float_style = "bright", -- 'bright' | 'dim'
        colours_override = function(colours) end,
        on_highlights = function(hl, palette) end,
      }
      -- Note: intentionally does NOT call vim.cmd.colorscheme here so that
      -- Catppuccin remains the default. Select Everforest via the picker.
    end,
  },

  {
    "rockerBOO/boo-colorscheme-nvim",
  },

  {
    "sainnhe/gruvbox-material",
    priority = 1000,
    opts = ...,
    config = function()
      vim.o.background = "dark"
      vim.g.gruvbox_material_enable_italic = true
      -- vim.cmd.colorscheme "gruvbox-material"
    end,
  },

  {
    "rose-pine/neovim",
    name = "rose-pine",
    config = function()
      vim.cmd "colorscheme rose-pine-moon"
    end,
  },
}
