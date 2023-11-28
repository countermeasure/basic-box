return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, {
        -- Add treesitter parsers which are not included by LazyVim.
        "comment",
        "css",
        "fish",
        "make",
        "scss",
        "toml",
      })
    end,
  },
}
