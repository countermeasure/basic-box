-- Change the LazyVim keymaps which start with "<leader>f" to start with
-- "<leader>F" to clear the way to map ranger to "<leader>f".
local Util = require("lazyvim.util")

return {
  {
    "nvim-telescope/telescope.nvim",
    keys = function()
      return {
        {
          "<leader>Fb",
          "<cmd>Telescope buffers sort_mru=true sort_lastused=true<cr>",
          desc = "Buffers",
        },
        {
          "<leader>Fc",
          LazyVim.pick.config_files(),
          desc = "Find Config File",
        },
        { "<leader>Ff", LazyVim.pick("files"), desc = "Find Files (Root Dir)" },
        {
          "<leader>FF",
          LazyVim.pick("files", { root = false }),
          desc = "Find Files (cwd)",
        },
        {
          "<leader>Fg",
          "<cmd>Telescope git_files<cr>",
          desc = "Find Files (git-files)",
        },
        { "<leader>Fr", "<cmd>Telescope oldfiles<cr>", desc = "Recent" },
        {
          "<leader>FR",
          LazyVim.pick("oldfiles", { cwd = vim.uv.cwd() }),
          desc = "Recent (cwd)",
        },
      }
    end,
  },
}
