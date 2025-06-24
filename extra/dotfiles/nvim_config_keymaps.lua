-- Tab between buffers.
vim.keymap.set(
  "n",
  "<S-Tab>",
  "<cmd>BufferLineCyclePrev<cr>",
  { desc = "Prev buffer" }
)
vim.keymap.set(
  "n",
  "<Tab>",
  "<cmd>BufferLineCycleNext<cr>",
  { desc = "Next buffer" }
)

-- Change the LazyVim keymaps which start with "<leader>f" to start with
-- "<leader>F" to clear the way to map ranger to "<leader>f".
vim.keymap.del("n", "<leader>fn")
vim.keymap.set("n", "<leader>Fn", "<cmd>enew<cr>", { desc = "New File" })
local Util = require("lazyvim.util")
local lazyterm = function()
  Util.float_term(nil, { cwd = Util.get_root() })
end
vim.keymap.del("n", "<leader>ft")
vim.keymap.set("n", "<leader>Ft", lazyterm, { desc = "Terminal (root dir)" })
vim.keymap.del("n", "<leader>fT")
vim.keymap.set("n", "<leader>FT", function()
  Util.float_term()
end, { desc = "Terminal (cwd)" })

-- Move the current line to the bottom of the buffer.
vim.keymap.set("n", "mb", function()
  local view = vim.fn.winsaveview()
  vim.cmd("normal ddGp")
  vim.fn.winrestview(view)
end, { desc = "Move line to start of buffer" })

-- Move the current selection to the bottom of the buffer.
vim.keymap.set("v", "mb", function()
  local view = vim.fn.winsaveview()
  vim.cmd("normal dGp")
  vim.fn.winrestview(view)
end, { desc = "Move line to start of buffer" })

-- Move the current line to the top of the buffer.
vim.keymap.set("n", "mt", function()
  local view = vim.fn.winsaveview()
  vim.cmd("normal ddggP")
  vim.fn.winrestview(view)
  vim.cmd("normal j")
end, { desc = "Move line to start of buffer" })

-- Move the current selection to the top of the buffer.
vim.keymap.set("v", "mt", function()
  local view = vim.fn.winsaveview()
  vim.cmd("normal dggP")
  vim.fn.winrestview(view)
  vim.cmd("normal j")
end, { desc = "Move line to start of buffer" })
