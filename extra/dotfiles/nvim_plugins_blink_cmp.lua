-- -- Enable supertab completion behaviour.
return {
  "Saghen/blink.cmp",
  opts = {
    keymap = {
      preset = "enter",
      ["<Tab>"] = { "select_next", "fallback" },
      ["<S-Tab>"] = { "select_prev", "fallback" },
    },
    completion = { list = { selection = { preselect = false } } },
  },
}
