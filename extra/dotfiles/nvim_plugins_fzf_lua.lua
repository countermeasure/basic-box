return {
  "ibhagwan/fzf-lua",
  keys = {
    -- Remap the default <leader>fb to <leader>Fb.
    { "<leader>fb", false },
    {
      "<leader>Fb",
      "<cmd>FzfLua buffers sort_mru=true sort_lastused=true<cr>",
      desc = "Buffers",
    },
    -- Remap the default <leader>fc to <leader>Fc.
    { "<leader>fc", false },
    { "<leader>Fc", LazyVim.pick.config_files(), desc = "Find Config File" },
    -- Remap the default <leader>ff to <leader>Ff.
    { "<leader>ff", false },
    { "<leader>Ff", LazyVim.pick("files"), desc = "Find Files (Root Dir)" },
    -- Remap the default <leader>fF to <leader>FF.
    { "<leader>fF", false },
    {
      "<leader>FF",
      LazyVim.pick("files", { root = false }),
      desc = "Find Files (cwd)",
    },
    -- Remap the default <leader>fF to <leader>FF.
    { "<leader>fg", false },
    {
      "<leader>Fg",
      "<cmd>FzfLua git_files<cr>",
      desc = "Find Files (git-files)",
    },
    -- Remap the default <leader>fF to <leader>FF.
    { "<leader>fr", false },
    { "<leader>Fr", "<cmd>FzfLua oldfiles<cr>", desc = "Recent" },
    -- Remap the default <leader>fR to <leader>FR.
    { "<leader>fR", false },
    {
      "<leader>FR",
      LazyVim.pick("oldfiles", { cwd = vim.uv.cwd() }),
      desc = "Recent (cwd)",
    },
  },
}
