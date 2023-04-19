return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- LazyVim tries to install jsonls, but it requires npm, so don't
        -- install it.
        jsonls = { mason = false },
        pylsp = {
          -- Don't install pylsp with Mason.
          mason = false,
          settings = {
            pylsp = {
              plugins = {
                -- flake8 is not enabled by default, but it is wanted.
                flake8 = { enabled = true },
                -- mccabe is enabled by default, but it is not wanted.
                mccabe = { enabled = false },
                -- pycodestyle is enabled by default, but it is not wanted.
                pycodestyle = { enabled = false },
                -- pyflakes is enabled by default, but it is not wanted.
                pyflakes = { enabled = false },
              },
            },
          },
        },
      },
    },
  },
}
