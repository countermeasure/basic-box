return {
  {
    "folke/which-key.nvim",
    opts = {
      icons = {
        group = " ",
      },
      -- Change the LazyVim keymaps which start with "<leader>f" to start with
      -- "<leader>F" to clear the way to map ranger to "<leader>f".
      spec = {
        { "<leader>f", desc = "File manager", icon = "TODO" },
        { "<leader>F", desc = "+file/find" },
      },
    },
  },
}
