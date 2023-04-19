-- Change the LazyVim keymaps which start with "<leader>f" to start with
-- "<leader>F" to clear the way to map ranger to "<leader>f".
local Util = require("lazyvim.util")

return {
  {
    "nvim-telescope/telescope.nvim",
    keys = function()
      return {
        { "<leader>Fb", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
        {
          "<leader>Ff",
          Util.telescope("files"),
          desc = "Find Files (root dir)",
        },
        {
          "<leader>FF",
          Util.telescope("files", { cwd = false }),
          desc = "Find Files (cwd)",
        },
        { "<leader>Fr", "<cmd>Telescope oldfiles<cr>", desc = "Recent" },
        {
          "<leader>FR",
          Util.telescope("oldfiles", { cwd = vim.loop.cwd() }),
          desc = "Recent (cwd)",
        },
      }
    end,
  },
}
