-- ===================================================================
-- Treesitter Incremental Selection (manual reimplementation)
-- ===================================================================
-- The nvim-treesitter `main`-branch rewrite dropped the built-in
-- `incremental_selection` module. This reimplements grow/shrink selection on
-- top of Neovim's core treesitter API (`vim.treesitter.get_node`).
--
--   <C-space> (normal) - start selection at the node under the cursor
--   <C-space> (visual) - grow selection to the parent node
--   <C-s>     (visual) - grow selection (scope alias)
--   <M-space> (visual) - shrink selection to the previous node

local M = {}

-- Per-buffer stack of selected nodes so shrink can walk back down the tree.
local stack = {}

-- Compare two nodes' ranges (nodes often share a range with their parent).
local function range_eq(a, b)
  local a1, a2, a3, a4 = a:range()
  local b1, b2, b3, b4 = b:range()
  return a1 == b1 and a2 == b2 and a3 == b3 and a4 == b4
end

-- Select a node's range charwise in visual mode.
local function update_selection(bufnr, node)
  local srow, scol, erow, ecol = node:range()
  -- Treesitter end column is exclusive; when it lands on column 0 the node
  -- really ends at the end of the previous line.
  if ecol == 0 then
    erow = math.max(erow - 1, 0)
    ecol = math.max(#(vim.api.nvim_buf_get_lines(bufnr, erow, erow + 1, true)[1] or ''), 0)
  end
  -- Leave any active visual mode so `v` starts a fresh charwise selection.
  if vim.fn.mode():match '[vV\22]' then
    vim.cmd 'normal! \27'
  end
  vim.api.nvim_win_set_cursor(0, { srow + 1, scol })
  vim.cmd 'normal! v'
  vim.api.nvim_win_set_cursor(0, { erow + 1, math.max(ecol - 1, 0) })
end

-- Start selection at the smallest node under the cursor.
function M.init()
  local bufnr = vim.api.nvim_get_current_buf()
  local node = vim.treesitter.get_node()
  if not node then
    return
  end
  stack[bufnr] = { node }
  update_selection(bufnr, node)
end

-- Grow selection to the nearest ancestor with a larger range.
function M.increment()
  local bufnr = vim.api.nvim_get_current_buf()
  local nodes = stack[bufnr]
  if not nodes then
    return M.init()
  end
  local node = nodes[#nodes]
  local parent = node:parent()
  while parent and range_eq(parent, node) do
    parent = parent:parent()
  end
  if parent then
    table.insert(nodes, parent)
    update_selection(bufnr, parent)
  end
end

-- Shrink selection to the previously selected node.
function M.decrement()
  local bufnr = vim.api.nvim_get_current_buf()
  local nodes = stack[bufnr]
  if not nodes or #nodes <= 1 then
    return
  end
  table.remove(nodes)
  update_selection(bufnr, nodes[#nodes])
end

return M
