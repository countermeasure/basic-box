return {
  {
    "williamboman/mason.nvim",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, {
        -- Add shellcheck.
        "shellcheck",
      })
    end,
  },
}
