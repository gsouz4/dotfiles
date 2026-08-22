-- ===================================================================
-- LSP Configuration - Language Server Protocol
-- ===================================================================
-- Complete LSP setup with Mason for automatic server management
-- See: https://github.com/neovim/nvim-lspconfig
-- See: https://github.com/williamboman/mason.nvim

return {
  -- ===================================================================
  -- LazyDev - Lua LSP for Neovim Configuration
  -- ===================================================================
  -- Enhanced Lua LSP specifically for Neovim config development
  {
    'folke/lazydev.nvim',
    ft = 'lua', -- Only load for Lua files
    opts = {
      library = {
        -- Load luvit types when the `vim.uv` word is found
        { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
      },
    },
  },

  -- ===================================================================
  -- Main LSP Configuration
  -- ===================================================================
  {
    'neovim/nvim-lspconfig',
    dependencies = {
      -- Mason must be loaded first
      { 'williamboman/mason.nvim', opts = {} },
      'williamboman/mason-lspconfig.nvim',
      'WhoIsSethDaniel/mason-tool-installer.nvim',

      -- LSP status updates
      { 'j-hui/fidget.nvim', opts = {} },

      -- Enhanced capabilities from nvim-cmp
      'hrsh7th/cmp-nvim-lsp',
    },

    config = function()
      -- ===================================================================
      -- What is LSP?
      -- ===================================================================
      -- LSP (Language Server Protocol) enables editors and language tooling
      -- to communicate in a standardized way. Language servers like `lua_ls`,
      -- `rust_analyzer`, `gopls` run as separate processes and provide:
      --
      -- - Go to definition/references
      -- - Autocompletion
      -- - Symbol search
      -- - Error diagnostics
      -- - Code actions and refactoring
      -- - Hover documentation
      --
      -- Mason automatically installs and manages these language servers.
      -- See `:help lsp-vs-treesitter` for LSP vs Treesitter comparison.

      -- ===================================================================
      -- Diagnostic Configuration
      -- ===================================================================
      -- Configure how LSP diagnostics are displayed
      vim.diagnostic.config {
        -- Sort diagnostics by severity (errors first)
        severity_sort = true,

        -- Floating window style for diagnostic details
        float = {
          border = 'rounded',
          source = 'if_many', -- Show source if multiple sources
        },

        -- Only underline errors (reduce visual noise)
        underline = {
          severity = vim.diagnostic.severity.ERROR,
        },

        -- Sign column icons (if Nerd Font available)
        signs = vim.g.have_nerd_font and {
          text = {
            [vim.diagnostic.severity.ERROR] = '󰅚 ',
            [vim.diagnostic.severity.WARN] = '󰀪 ',
            [vim.diagnostic.severity.INFO] = '󰋽 ',
            [vim.diagnostic.severity.HINT] = '󰌶 ',
          },
        } or {},

        -- Virtual text configuration
        virtual_text = {
          source = 'if_many', -- Show source if multiple
          spacing = 2, -- Space between text and diagnostic
          format = function(diagnostic)
            return diagnostic.message
          end,
        },
      }

      -- ===================================================================
      -- LSP Capabilities
      -- ===================================================================
      -- Extend default LSP capabilities with completion support
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      capabilities = vim.tbl_deep_extend('force', capabilities, require('cmp_nvim_lsp').default_capabilities())

      -- ===================================================================
      -- Language Server Configuration
      -- ===================================================================
      -- Define language servers and their specific settings
      -- Add/remove servers as needed for your projects
      local servers = {
        -- Rust Language Server
        rust_analyzer = {
          settings = {
            ['rust-analyzer'] = {
              -- Use cargo check on save (run clippy manually via make lint)
              checkOnSave = {
                command = 'check',
              },

              -- Enable procedural macros
              procMacro = {
                enable = true,
              },

              -- Import configuration
              assist = {
                importGranularity = 'module',
                importPrefix = 'self',
              },

              -- Enhanced diagnostics
              diagnostics = {
                enable = true,
                experimental = {
                  enable = true,
                },
              },

              -- Inlay hints for better code understanding
              inlayHints = {
                enable = true,
                parameterHints = {
                  enable = true,
                },
                typeHints = {
                  enable = true,
                },
              },
            },
          },
        },

        -- Lua Language Server (for Neovim configuration)
        lua_ls = {
          settings = {
            Lua = {
              completion = {
                callSnippet = 'Replace',
              },
              -- Uncomment to disable noisy missing-fields warnings
              -- diagnostics = { disable = { 'missing-fields' } },
            },
          },
        },

        -- Go Language Server
        -- Binary comes from mise (`go:golang.org/x/tools/gopls` in
        -- .tool-versions), not Mason -- see the enable block below.
        gopls = {
          settings = {
            gopls = {
              -- Report unused parameters and shadowed variables
              analyses = {
                unusedparams = true,
                shadow = true,
              },

              -- Run staticcheck alongside the default vet analysers
              staticcheck = true,

              -- Stricter gofmt (matches the gofumpt formatter in conform)
              gofumpt = true,

              -- Inlay hints, mirroring the rust_analyzer setup above
              hints = {
                parameterNames = true,
                assignVariableTypes = true,
                compositeLiteralTypes = true,
                functionTypeParameters = true,
              },
            },
          },
        },

        -- TypeScript / JavaScript Language Server
        -- Root dir and filetypes come from nvim-lspconfig's bundled `lsp/ts_ls.lua`,
        -- which vim.lsp.config merges with the table below.
        ts_ls = {
          settings = {
            -- Inlay hints, mirroring the rust_analyzer and gopls setups above.
            -- ts_ls keeps a separate settings block per language: the JS one is
            -- not inherited from the TS one, so both have to be spelled out.
            typescript = {
              inlayHints = {
                includeInlayParameterNameHints = 'literals',
                includeInlayParameterNameHintsWhenArgumentMatchesName = false,
                includeInlayFunctionParameterTypeHints = true,
                includeInlayVariableTypeHints = false,
                includeInlayPropertyDeclarationTypeHints = true,
                includeInlayFunctionLikeReturnTypeHints = true,
                includeInlayEnumMemberValueHints = true,
              },
            },
            javascript = {
              inlayHints = {
                includeInlayParameterNameHints = 'literals',
                includeInlayParameterNameHintsWhenArgumentMatchesName = false,
                includeInlayFunctionParameterTypeHints = true,
                includeInlayVariableTypeHints = false,
                includeInlayPropertyDeclarationTypeHints = true,
                includeInlayFunctionLikeReturnTypeHints = true,
                includeInlayEnumMemberValueHints = true,
              },
            },
          },
        },

        -- Add more servers as needed:
        -- Python: pyright = {} or pylsp = {}
        -- C/C++: clangd = {}
        -- See `:help lspconfig-all` for complete list
      }

      -- ===================================================================
      -- Mason Tool Installation
      -- ===================================================================
      -- Automatically install language servers and related tools.
      -- gopls is excluded: it is managed by mise via .tool-versions, and letting
      -- Mason install a second copy would leave two binaries racing on PATH.
      local mason_managed = vim.tbl_filter(function(name)
        return name ~= 'gopls'
      end, vim.tbl_keys(servers or {}))

      local ensure_installed = vim.list_extend(mason_managed, {
        'stylua', -- Lua formatter

        -- Web formatters. conform maps js/ts/json/css/... to prettierd with a
        -- prettier fallback (see coding/formatting.lua); without these two
        -- installed, `<leader>f` on a TS buffer silently did nothing.
        'prettierd',
        'prettier',

        -- Add other tools as needed:
        -- 'eslint_d', 'black', 'isort', etc.
      })

      require('mason-tool-installer').setup {
        ensure_installed = ensure_installed,
      }

      -- ===================================================================
      -- LSP Server Setup
      -- ===================================================================
      -- mason-lspconfig v2 removed the `handlers` and `automatic_installation`
      -- options. They were silently ignored here, which meant none of the
      -- settings in the `servers` table above ever reached a language server --
      -- rust_analyzer and lua_ls were running on stock defaults.
      --
      -- The replacement is the built-in vim.lsp.config registry (nvim 0.11+):
      -- register settings per server, then enable the server.
      for name, server in pairs(servers) do
        server.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server.capabilities or {})
        vim.lsp.config(name, server)
      end

      require('mason-lspconfig').setup {
        -- Installation is mason-tool-installer's job (see above)
        ensure_installed = {},

        -- Enable anything Mason installed: lua_ls, rust_analyzer, and
        -- golangci_lint_ls (Go diagnostics, installed via the Mason UI)
        automatic_enable = true,
      }

      -- gopls comes from mise rather than Mason, so `automatic_enable` never
      -- sees it and nothing would start it. Without this, the only client
      -- attaching to a Go buffer is golangci_lint_ls -- a diagnostics-only
      -- server -- and `gd`/`gr`/`K` fail with "method textDocument/definition
      -- is not supported by any server activated for this buffer".
      if vim.fn.executable 'gopls' == 1 then
        vim.lsp.enable 'gopls'

        -- Run `source.organizeImports` before saving Go files so gopls adds
        -- missing imports and removes unused ones (goimports behaviour).
        vim.api.nvim_create_autocmd('BufWritePre', {
          pattern = '*.go',
          callback = function()
            local params = vim.lsp.util.make_range_params(0, 'utf-8')
            params.context = { only = { 'source.organizeImports' } }
            local result = vim.lsp.buf_request_sync(0, 'textDocument/codeAction', params, 1000)
            for _, res in pairs(result or {}) do
              for _, action in pairs(res.result or {}) do
                if action.edit then
                  vim.lsp.util.apply_workspace_edit(action.edit, 'utf-8')
                end
              end
            end
          end,
        })
      else
        vim.notify('gopls not found on PATH; Go LSP disabled. Run: mise install', vim.log.levels.WARN)
      end

      -- ===================================================================
      -- Module Exports for Testing
      -- ===================================================================
      -- Export server configuration for testing purposes
      _G.lsp_servers = servers
      _G.lsp_capabilities = capabilities
    end,
  },
}
