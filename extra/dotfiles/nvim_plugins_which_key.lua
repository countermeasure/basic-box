return {
  {
    "folke/which-key.nvim",
    opts = {
      -- Change the LazyVim keymaps which start with "<leader>f" to start with
      -- "<leader>F" to clear the way to map ranger to "<leader>f".
      defaults = {
        ["<leader>f"] = "File manager",
        ["<leader>F"] = { name = "+file/find" },
      },
      icons = {
        group = "  ",
        separator = "➜ ",
      },
    },
  },
}
