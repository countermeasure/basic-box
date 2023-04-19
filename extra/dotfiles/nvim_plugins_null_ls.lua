return {
  {
    "jose-elias-alvarez/null-ls.nvim",
    opts = function(_, opts)
      local nls = require("null-ls")
      opts.sources = vim.list_extend(opts.sources, {
        -- Add shellcheck.
        nls.builtins.code_actions.shellcheck,
        nls.builtins.diagnostics.shellcheck,
        -- Configure shfmt to be consistent with the Google Shell Style Guide.
        nls.builtins.formatting.shfmt.with({
          extra_args = {
            "--binary-next-line",
            "--case-indent",
            "--indent",
            "2",
          },
        }),
      })
    end,
  },
}
