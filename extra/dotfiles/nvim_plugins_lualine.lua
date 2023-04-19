local function word_count()
  if
    vim.bo.filetype == "markdown"
    or vim.bo.filetype == "rst"
    or vim.bo.filetype == "text"
  then
    if vim.fn.wordcount().visual_words == nil then
      return " " .. vim.fn.wordcount().words
    else
      return " " .. vim.fn.wordcount().visual_words
    end
  else
    return ""
  end
end

return {
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    opts = function()
      local icons = require("lazyvim.config").icons
      local Util = require("lazyvim.util")

      return {
        options = {
          disabled_filetypes = { statusline = { "dashboard", "alpha" } },
          globalstatus = true,
          section_separators = { left = "", right = "" },
          theme = "auto",
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
              "branch",
              fmt = function(str)
                if str:len() > 15 then
                  return str:sub(1, 14) .. "…"
                else
                  return str
                end
              end,
              icon = "",
              padding = 1,
            },
          },
          lualine_c = {
            {
              "diagnostics",
              separator = "•",
              symbols = {
                error = icons.diagnostics.Error,
                hint = icons.diagnostics.Hint,
                info = icons.diagnostics.Info,
                warn = icons.diagnostics.Warn,
              },
            },
            {
              "filetype",
              icon_only = true,
              padding = { left = 1 },
              separator = "",
            },
            {
              "filename",
              path = 3,
              separator = "•",
              symbols = { modified = "", readonly = "", unnamed = "" },
            },
            {
              function()
                return require("nvim-navic").get_location()
              end,
              cond = function()
                return package.loaded["nvim-navic"]
                  and require("nvim-navic").is_available()
              end,
            },
          },
          lualine_x = {
            {
              function()
                return require("noice").api.status.command.get()
              end,
              cond = function()
                return package.loaded["noice"]
                  and require("noice").api.status.command.has()
              end,
              color = Util.fg("Statement"),
              separator = "•",
            },
            {
              function()
                return require("noice").api.status.mode.get()
              end,
              cond = function()
                return package.loaded["noice"]
                  and require("noice").api.status.mode.has()
              end,
              color = Util.fg("Constant"),
              separator = "•",
            },
            {
              function()
                return "  " .. require("dap").status()
              end,
              cond = function()
                return package.loaded["dap"] and require("dap").status() ~= ""
              end,
              color = Util.fg("Debug"),
              separator = "•",
            },
            {
              require("lazy.status").updates,
              cond = require("lazy.status").has_updates,
              color = Util.fg("Special"),
              padding = 1,
              separator = "•",
            },
            {
              "diff",
              symbols = {
                added = icons.git.added,
                modified = icons.git.modified,
                removed = icons.git.removed,
              },
            },
          },
          lualine_y = {
            {
              "searchcount",
              icon = "",
              padding = 1,
              separator = "",
            },
            {
              word_count,
              padding = 1,
            },
          },
          lualine_z = {
            {
              "%v",
              icon = "",
              padding = 1,
              separator = "",
            },
            {
              "%l/%L",
              icon = "",
              padding = { left = 1, right = 2 },
            },
          },
        },
        extensions = { "neo-tree", "lazy" },
      }
    end,
  },
}
