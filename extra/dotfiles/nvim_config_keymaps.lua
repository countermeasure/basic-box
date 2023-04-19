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
