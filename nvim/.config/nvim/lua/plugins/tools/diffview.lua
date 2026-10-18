-- ===================================================================
-- Diffview Configuration
-- ===================================================================
-- Full-repo diff review: file panel with every change on the left,
-- side-by-side diff of the selected file on the right, all in one tab.
-- Complements the snacks git_status picker (`;gs`), which shows one
-- file at a time.
-- See: https://github.com/sindrets/diffview.nvim

-- `base...HEAD` diffs from the merge-base, so only what the current
-- branch added shows up: the same diff GitHub renders for a PR.
local function diff_against(base)
  vim.cmd('DiffviewOpen ' .. base .. '...HEAD')
end

-- The remote's default branch (main, master, ...), as `origin/<name>`.
-- `origin/HEAD` is only set on clones; fall back to origin/main.
local function default_branch()
  local ref = vim.fn.systemlist({ 'git', 'symbolic-ref', '--short', 'refs/remotes/origin/HEAD' })[1]
  if vim.v.shell_error ~= 0 or not ref or ref == '' then
    return 'origin/main'
  end
  return ref
end

return {
  'sindrets/diffview.nvim',

  -- Lazy-loaded: only pulled in on first command or keymap
  cmd = { 'DiffviewOpen', 'DiffviewClose', 'DiffviewFileHistory', 'DiffviewToggleFiles', 'DiffviewRefresh' },

  keys = {
    -- Toggle so the same key opens and closes the review tab
    {
      '<leader>gd',
      function()
        if require('diffview.lib').get_current_view() then
          vim.cmd.DiffviewClose()
        else
          vim.cmd.DiffviewOpen()
        end
      end,
      desc = '[G]it [D]iffview (all changes)',
    },
    {
      '<leader>gm',
      function()
        diff_against(default_branch())
      end,
      desc = '[G]it diff vs [M]ain (branch as a PR)',
    },
    {
      '<leader>gD',
      function()
        -- Pick any local or remote branch; confirm diffs instead of checking out
        Snacks.picker.git_branches {
          all = true,
          confirm = function(picker, item)
            picker:close()
            if item and item.branch then
              diff_against((item.branch:gsub('^remotes/', '')))
            end
          end,
        }
      end,
      desc = '[G]it [D]iff vs branch (picker)',
    },
    { '<leader>gh', '<cmd>DiffviewFileHistory %<cr>', desc = '[G]it file [H]istory' },
    { '<leader>gH', '<cmd>DiffviewFileHistory<cr>', desc = '[G]it repo [H]istory' },
  },

  config = function()
    -- Better hunk alignment inside diffs (Neovim's internal diff engine)
    vim.opt.diffopt:append 'linematch:60'

    require('diffview').setup {
      -- Use the same fold/sign column look as normal buffers
      enhanced_diff_hl = true,

      view = {
        -- Working tree and history diffs: plain two-pane split
        default = { layout = 'diff2_horizontal' },
        file_history = { layout = 'diff2_horizontal' },
      },

      file_panel = {
        listing_style = 'tree',
        win_config = {
          position = 'left',
          width = 35,
        },
      },

      hooks = {
        -- Diff mode uses `foldmethod=diff` with `foldlevel=0`, so every
        -- unchanged region starts folded and the file reads as fragments.
        -- Open all folds instead: the whole file is visible, and `zM`/`zc`
        -- still fold the context back when a file is too long to scroll.
        diff_buf_win_enter = function(_, winid)
          vim.wo[winid].foldlevel = 99
        end,
      },

      keymaps = {
        -- `q` closes the whole review from anywhere inside it
        view = { { 'n', 'q', '<cmd>DiffviewClose<cr>', { desc = 'Close diffview' } } },
        file_panel = { { 'n', 'q', '<cmd>DiffviewClose<cr>', { desc = 'Close diffview' } } },
        file_history_panel = { { 'n', 'q', '<cmd>DiffviewClose<cr>', { desc = 'Close diffview' } } },
      },
    }
  end,
}
