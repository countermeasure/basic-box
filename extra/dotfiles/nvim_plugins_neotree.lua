-- Change the LazyVim keymaps which start with "<leader>f" to start with
-- "<leader>F" to clear the way to map ranger to "<leader>f".
return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    keys = {
      { "<leader>fe", false },
      {
        "<leader>Fe",
        function()
          require("neo-tree.command").execute({
            toggle = true,
            dir = LazyVim.root(),
          })
        end,
        desc = "Explorer NeoTree (Root Dir)",
      },
      { "<leader>fE", false },
      {
        "<leader>FE",
        function()
          require("neo-tree.command").execute({
            toggle = true,
            dir = vim.uv.cwd(),
          })
        end,
        desc = "Explorer NeoTree (cwd)",
      },
      {
        "<leader>e",
        "<leader>Fe",
        desc = "Explorer NeoTree (Root Dir)",
        remap = true,
      },
      {
        "<leader>E",
        "<leader>FE",
        desc = "Explorer NeoTree (cwd)",
        remap = true,
      },
    },
  },
}
