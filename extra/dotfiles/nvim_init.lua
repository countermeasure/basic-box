-- PLUGINS --

-- Plugin manager --

require("packer").startup(function()
  -- Buffer line.
  use({ "akinsho/bufferline.nvim", commit = "f02e19b" })
  -- Diagnostics list.
  use({ "folke/trouble.nvim", commit = "691d490" })
  -- Key binding list.
  use({ "folke/which-key.nvim", commit = "a3c19ec" })
  -- Ranger integration.
  use({ "francoiscabrol/ranger.vim", commit = "91e82de" })
  -- Motions.
  use({ "ggandor/lightspeed.nvim", commit = "cfde2b2" })
  -- Auto-completion source for buffer contents.
  use({ "hrsh7th/cmp-buffer", commit = "d66c4c2" })
  -- Auto-completion source for LSP client.
  use({ "hrsh7th/cmp-nvim-lsp", commit = "ebdfc20" })
  -- Auto-completion source for functions with parameter highlighting.
  use({ "hrsh7th/cmp-nvim-lsp-signature-help", commit = "8014f6d" })
  -- Auto-completion source for filesystem paths.
  use({ "hrsh7th/cmp-path", commit = "466b6b8" })
  -- Auto-completion engine.
  use({ "hrsh7th/nvim-cmp", commit = "433af3d" })
  -- Use non-LSP sources with LSP client.
  use({ "jose-elias-alvarez/null-ls.nvim", commit = "0c7624f" })
  -- Colourscheme.
  use({ "joshdick/onedark.vim", commit = "7db2ed5" })
  -- Icons. Required by bufferline.nvim, lualine.nvim, trouble.nvim.
  use({ "kyazdani42/nvim-web-devicons", commit = "4febe73" })
  -- Git decorations and functionality.
  use({ "lewis6991/gitsigns.nvim", commit = "ead0d48" })
  -- Tag manager.
  use({ "ludovicchabant/vim-gutentags", commit = "50705e8" })
  -- Indentation guides, including on blank lines.
  use({ "lukas-reineke/indent-blankline.nvim", commit = "045d958" })
  -- LSP client configurations.
  use({ "neovim/nvim-lspconfig", commit = "ad9903c" })
  -- Miscellaneous Lua functions. Required by null-ls.nvim, telescope.nvim.
  use({ "nvim-lua/plenary.nvim", commit = "9069d14" })
  -- Status line.
  use({ "nvim-lualine/lualine.nvim", commit = "18a07f7" })
  -- Fuzzy finder.
  use({ "nvim-telescope/telescope.nvim", commit = "8b02088" })
  -- Port of fzf to improve the performance of telescope.nvim.
  use({
    "nvim-telescope/telescope-fzf-native.nvim",
    commit = "8ec164b",
    run = "make",
  })
  -- Parser for syntax highlighting, navigation, etc.
  use({
    "nvim-treesitter/nvim-treesitter",
    commit = "3c50297",
    run = ":TSUpdate",
  })
  -- Additional mappings for nvim-treesitter/nvim-treesitter.
  use({ "nvim-treesitter/nvim-treesitter-textobjects", commit = "094e8ad" })
  -- Delete buffer without closing window. Required by ranger.vim.
  use({ "rbgrouleff/bclose.vim", commit = "99018b4" })
  -- Commenting.
  use({ "tpope/vim-commentary", commit = "3654775" })
  -- Git integration.
  use({ "tpope/vim-fugitive", commit = "b5bbd0d" })
  -- Repeating plugin maps. Used by gitsigns.nvim, lightspeed.nvim,
  -- surround.vim.
  use({ "tpope/vim-repeat", commit = "24afe92" })
  -- Automatic buffer option adjustment.
  use({ "tpope/vim-sleuth", commit = "e116c2c" })
  -- Surroundings.
  use({ "tpope/vim-surround", commit = "bf3480d" })
  -- Plugin manager.
  use({ "wbthomason/packer.nvim", commit = "4dedd3b" })
  -- Autopairing.
  use({ "windwp/nvim-autopairs", commit = "e9b47f0" })
end)

-- Plugin: akinsho/bufferline.nvim --

require("bufferline").setup({
  options = {
    show_buffer_close_icons = false,
    show_buffer_icons = false,
    show_close_icon = false,
  },
})

-- Plugin: folke/which-key.nvim --

local which_key = require("which-key")

which_key.setup({
  icons = {
    group = "  ",
    separator = "➜ ",
  },
  plugins = {
    spelling = { enabled = true },
  },
})

-- Double leader mappings for mappings which are less frequently used.
which_key.register({
  ["<leader><leader>"] = {
    name = "+Less frequently used",
    b = { name = "+Buffers" },
    bn = { "<cmd>enew<CR>", "New buffer" },
    c = { name = "+Code operations" },
    ca = { "<cmd>lua vim.lsp.buf.code_action()<CR>", "Code action" },
    cf = { "<cmd>lua vim.lsp.buf.formatting()<CR>", "Format code" },
    f = { name = "+Find files & text" },
    fb = { "<cmd>Telescope current_buffer_fuzzy_find<CR>", "Find in buffer" },
    fc = { "<cmd>Telescope grep_string<CR>", "Find string under cursor" },
    fd = { "<cmd>Telescope live_grep<CR>", "Find in directory" },
    ff = { "<cmd>Telescope find_files<CR>", "Find file" },
    fr = { "<cmd>Telescope oldfiles<CR>", "Find recent file" },
    g = { name = "+Git" },
    ga = { "<cmd>Gitsigns stage_hunk<CR>", "Git add" },
    gb = { "<cmd>Git blame<CR>", "Git blame" },
    gd = { "<cmd>Gitsigns preview_hunk<CR>", "Git diff" },
    gr = { "<cmd>Gitsigns reset_hunk<CR>", "Git reset" },
    gu = { "<cmd>Gitsigns undo_stage_hunk<CR>", "Git unstage" },
    q = { name = "+Quit" },
    qf = { "<cmd>quit!<CR>", "Quit with force" },
    s = { name = "+Save/spell" },
    sa = { "<cmd>wall<CR>", "Save all buffers" },
    sf = { "<cmd>write!<CR>", "Save buffer with force" },
    sp = { "<cmd>set spell!<CR>", "Toggle spellcheck" },
  },
})

-- LSP mappings.
local attach_lsp_mappings = function(_, bufnr)
  which_key.register({
    ["gd"] = { "<cmd>lua vim.lsp.buf.definition()<CR>", "Go to definition" },
    ["gr"] = { "<cmd>TroubleToggle lsp_references<CR>", "Show references" },
    ["K"] = { "<cmd>lua vim.lsp.buf.hover()<CR>", "Hover" },
    ["<leader><leader>"] = {
      cr = { "<cmd>lua vim.lsp.buf.rename()<CR>", "Rename" },
      fs = { "<cmd>Telescope lsp_document_symbols<CR>", "Show LSP symbols" },
    },
  })
end

-- Miscellaneous mappings.
which_key.register({
  ["//"] = { "<cmd>nohlsearch<CR>", "Search highlighting off" },
})

-- Navigation mappings.
which_key.register({
  ["<S-Tab>"] = { "<cmd>BufferLineCyclePrev<CR>", "Previous buffer" },
  ["<Tab>"] = { "<cmd>BufferLineCycleNext<CR>", "Next buffer" },
  ["[c"] = { "Previous class start" },
  ["[C"] = { "Previous class end" },
  ["[d"] = {
    "<cmd>lua vim.diagnostic.goto_prev()<CR>",
    "Previous diagnostic message",
  },
  ["[f"] = { "Previous function start" },
  ["[F"] = { "Previous function end" },
  ["[g"] = { "<cmd>Gitsigns prev_hunk<CR>", "Previous Git hunk" },
  ["]c"] = { "Next class start" },
  ["]C"] = { "Next class end" },
  ["]d"] = {
    "<cmd>lua vim.diagnostic.goto_next()<CR>",
    "Next diagnostic message",
  },
  ["]f"] = { "Next function start" },
  ["]F"] = { "Next function end" },
  ["]g"] = { "<cmd>Gitsigns next_hunk<CR>", "Next Git hunk" },
  ["s"] = { "<Plug>Lightspeed_omni_s", "Lightspeed search" },
})

-- Single leader mappings for mappings which are more frequently used.
which_key.register({
  ["<leader>"] = {
    c = { "<cmd>bdelete<bar>bnext<CR>", "Close buffer" },
    d = { "<cmd>TroubleToggle<CR>", "Toggle diagnostics" },
    f = "File manager",
    h = { "<cmd>Telescope help_tags<CR>", "Help" },
    m = { "<cmd>WhichKey<CR>", "Show mappings" },
    q = { "<cmd>quit<CR>", "Quit" },
    s = { "<cmd>write<CR>", "Save buffer" },
  },
})

-- Text object mappings.
which_key.register({
  ["ac"] = { "a class" },
  ["af"] = { "a function" },
  ["ic"] = { "inner class" },
  ["if"] = { "inner function" },
}, { mode = "o" })

-- Plugin: francoiscabrol/ranger.vim --

-- Open ranger when Neovim opens to a directory.
vim.g.ranger_replace_netrw = 1

-- Plugins: hrsh7th/cmp-buffer --
--          hrsh7th/cmp-nvim-lsp --
--          hrsh7th/cmp-nvim-lsp-signature-help --
--          hrsh7th/cmp-path --
--          hrsh7th/nvim-cmp --

local cmp = require("cmp")
cmp.setup({
  mapping = cmp.mapping.preset.insert({
    ["<C-a>"] = cmp.mapping.abort(),
    ["<S-Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      else
        fallback()
      end
    end),
    ["<Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      else
        fallback()
      end
    end),
  }),
  sources = cmp.config.sources({
    { name = "buffer" },
    { name = "nvim_lsp" },
    { name = "nvim_lsp_signature_help" },
    { name = "path", option = { trailing_slash = true } },
  }),
})

-- Plugin: jose-elias-alvarez/null-ls.nvim --

local null_ls = require("null-ls")
null_ls.setup({
  sources = {
    null_ls.builtins.code_actions.shellcheck,
    null_ls.builtins.diagnostics.shellcheck,
    null_ls.builtins.formatting.stylua,
  },
})

-- Plugin: joshdick/onedark.vi --

-- Enable 24-bit colour.
vim.opt.termguicolors = true
-- The onedark README says to set this to 1 for terminals which support
-- italics.
vim.g.onedark_terminal_italics = 1
-- Load the onedark colourscheme.
vim.cmd("colorscheme onedark")

-- Plugin: lewis6991/gitsigns.nvim --

require("gitsigns").setup({
  -- Keymaps are unset because otherwise they pollute the <leader>h namespace.
  keymaps = {},
})

-- Plugin: ludovicchabant/vim-gutentags --

-- Exclude these file patterns from tags generation to keep tag file sizes
-- manageable.
vim.g.gutentags_ctags_exclude = {
  "*.css",
  "*.html",
  "*.js",
  "*.json",
  "*.md",
  "*.rst",
  "*.scss",
  "*.yml",
  ".direnv",
  ".tox",
  "node_modules",
}
-- Specify the name of the tag file, otherwise it defaults to "tags".
vim.g.gutentags_ctags_tagfile = ".ctags"

-- Plugin: lukas-reineke/indent-blankline.nvim --

require("indent_blankline").setup({
  show_current_context = true,
  show_end_of_line = true,
})

-- Plugin: neovim/nvim-lspconfig --

local servers = {
  pylsp = {
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
}

local capabilities = require("cmp_nvim_lsp").update_capabilities(
  vim.lsp.protocol.make_client_capabilities()
)
for server, settings in pairs(servers) do
  require("lspconfig")[server].setup({
    on_attach = attach_lsp_mappings,
    capabilities = capabilities,
    settings = settings,
  })
end

-- Plugin: nvim-lualine/lualine.nvim --

local function word_count()
  if vim.bo.filetype == "markdown" or vim.bo.filetype == "rst" then
    if vim.fn.wordcount().visual_words == nil then
      return " " .. vim.fn.wordcount().words
    else
      return " " .. vim.fn.wordcount().visual_words
    end
  else
    return ""
  end
end

require("lualine").setup({
  options = {
    section_separators = { left = "", right = "" },
  },
  sections = {
    lualine_a = {
      {
        "mode",
        fmt = string.lower,
        padding = { left = 2, right = 1 },
      },
    },
    lualine_b = {
      {
        "diagnostics",
        padding = { left = 2, right = 1 },
      },
    },
    lualine_c = {
      {
        "filename",
        color = { fg = "grey" },
        padding = { left = 2, right = 1 },
        path = 2,
        symbols = { modified = " ", readonly = " ", unnamed = "unnamed" },
      },
    },
    lualine_x = {
      {
        "filetype",
        color = { fg = "grey" },
        colored = false,
        icon_only = true,
        padding = { left = 1, right = 0 },
        separator = { right = nil },
      },
      {
        "encoding",
        color = { fg = "grey" },
        padding = { left = 1, right = 2 },
      },
    },
    lualine_y = {
      {
        "branch",
        fmt = function(str)
          if str:len() > 15 then
            return str:sub(1, 14) .. "…"
          else
            return str
          end
        end,
        icon = "",
        padding = { left = 1, right = 2 },
        separator = { left = "" },
      },
      {
        "diff",
        padding = { left = 0, right = 2 },
        source = function()
          local signs = vim.b.gitsigns_status_dict
          if signs then
            return {
              added = signs.added,
              modified = signs.changed,
              removed = signs.removed,
            }
          end
        end,
        symbols = { added = " ", modified = " ", removed = " " },
      },
    },
    lualine_z = {
      { word_count },
      {
        "%v",
        icon = "",
        padding = { left = 1, right = 1 },
        separator = { left = "" },
      },
      {
        "%l/%L",
        icon = "",
        padding = { left = 1, right = 2 },
      },
    },
  },
})

-- Plugins: nvim-telescope/telescope-fzf-native.nvim --
--          nvim-telescope/telescope.nvim --

require("telescope").load_extension("fzf")

-- Plugins: nvim-treesitter/nvim-treesitter --
--          nvim-treesitter/nvim-treesitter-textobjects --

require("nvim-treesitter.configs").setup({
  ensure_installed = {
    "bash",
    "comment",
    "css",
    "elm",
    "html",
    "http",
    "javascript",
    "json",
    "lua",
    "make",
    "markdown",
    "python",
    "regex",
    "scss",
    "toml",
    "yaml",
  },
  highlight = {
    enable = true,
  },
  indent = {
    enable = true,
  },
  textobjects = {
    move = {
      enable = true,
      goto_next_end = {
        ["]C"] = "@class.outer",
        ["]F"] = "@function.outer",
      },
      goto_next_start = {
        ["]c"] = "@class.outer",
        ["]f"] = "@function.outer",
      },
      goto_previous_end = {
        ["[C"] = "@class.outer",
        ["[F"] = "@function.outer",
      },
      goto_previous_start = {
        ["[c"] = "@class.outer",
        ["[f"] = "@function.outer",
      },
      -- Set jumps in the jumplist.
      set_jumps = true,
    },
    select = {
      enable = true,
      -- Jump forward to the next text object.
      lookahead = true,
      keymaps = {
        ["ac"] = "@class.outer",
        ["af"] = "@function.outer",
        ["ic"] = "@class.inner",
        ["if"] = "@function.inner",
      },
    },
  },
})

-- Use Tree-sitter based folding.
vim.wo.foldexpr = "nvim_treesitter#foldexpr()"
vim.wo.foldlevel = 99
vim.wo.foldmethod = "expr"

-- Plugin: rbgrouleff/bclose.vim.

-- Stop the <leader>bd mapping being created, because it's not needed.
vim.g.bclose_no_plugin_maps = true

-- Plugin: windwp/nvim-autopairs.

require("nvim-autopairs").setup({})

-- OPTIONS --

-- Make space the leader key.
vim.g.mapleader = " "

-- Make space the leader key for mappings local to a buffer.
vim.g.maplocalleader = " "

-- Specify the Python executable which runs the Python client.
vim.g.python3_host_prog = "$HOME/.local/pip/venvs/pynvim/bin/python"

-- Show wrapped text indented to match the start of the line.
vim.opt.breakindent = true

-- Show a completion popup when there is at least one completion option, and do
-- not select any option by default.
vim.opt.completeopt = "menu,menuone,noselect"

-- Highlight the column at column 80 (textwidth + 1).
vim.opt.colorcolumn = "+1"

-- Highlight the line the cursor is on.
vim.opt.cursorline = true

-- Make the cursor blink, and make it blue when it's not a block.
vim.opt.guicursor = "n-v-c-sm:block,"
  .. "i-ci-ve:ver25-Cursor,"
  .. "r-cr-o:hor20-Cursor,"
  .. "a:blinkwait700-blinkoff400-blinkon250"

-- Ignore case when searching, except when smartcase takes precedence.
vim.opt.ignorecase = true

-- Show invisible characters.
vim.opt.list = true

-- Show ends of lines as the "↴" character.
vim.opt.listchars:append("eol:↴")

-- Show tabs as the "" character.
vim.opt.listchars:append("tab: ")

-- Show trailing whitespace as the "•" character.
vim.opt.listchars:append("trail:•")

-- Show line numbers.
vim.opt.number = true

-- Make line numbers relative to the cursor position.
vim.opt.relativenumber = true

-- Always show at least one line above and below the cursor.
vim.opt.scrolloff = 1

-- Don't show the mode on the line below the statusline.
vim.opt.showmode = false

-- Make search case sensitive when the search term contains a capital.
vim.opt.smartcase = true

-- Maximum width of text is 79 characters.
vim.opt.textwidth = 79

-- Wait 500ms for mappings to be completed before showing which-key popup.
vim.opt.timeoutlen = 500

-- MAPPINGS WHICH SHOULDN'T BE MANAGED BY WHICH-KEY --

-- Make the space key a no-op because it is the <leader>.
vim.keymap.set("", "<Space>", "<Nop>", { silent = true })

-- When moving down through wrapped text, don't skip to the next line.
vim.keymap.set(
  "n",
  "j",
  "v:count == 0 ? 'gj' : 'j'",
  { expr = true, silent = true }
)

-- When moving up through wrapped text, don't skip to the next line.
vim.keymap.set(
  "n",
  "k",
  "v:count == 0 ? 'gk' : 'k'",
  { expr = true, silent = true }
)

-- AUTOCOMMANDS --

-- Remove trailing whitespace on save.
vim.api.nvim_create_autocmd("BufWritePre", {
  callback = function()
    local view = vim.fn.winsaveview()
    vim.cmd("keeppatterns %s/\\s\\+$//e")
    vim.fn.winrestview(view)
  end,
  pattern = "*",
})

-- Briefly highlight yanked text.
vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    vim.highlight.on_yank({ timeout = 250 })
  end,
  group = vim.api.nvim_create_augroup("YankHighlight", { clear = true }),
  pattern = "*",
})
