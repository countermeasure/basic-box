return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters = {
        -- Configure shfmt to be consistent with the Google Shell Style Guide.
        shfmt = {
          prepend_args = {
            "--binary-next-line",
            "--case-indent",
            "--indent",
            "2",
          },
        },
      },
    },
  },
}
