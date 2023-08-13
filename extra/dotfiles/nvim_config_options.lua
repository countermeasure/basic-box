-- Ranger opens more smoothly when its keymap is handled in its plugin file
-- rather than by its default keymap.
vim.g.ranger_map_keys = false

-- Show wrapped text indented to match the start of the line.
vim.opt.breakindent = true

-- Draw a ruler at textwidth + 1.
vim.opt.colorcolumn = "+1"

-- Blink the cursor.
vim.opt.guicursor:append("a:blinkwait700-blinkoff400-blinkon250")

-- Show ends of lines as the "↴" character.
vim.opt.listchars:append("eol:↴")

-- Show multiple spaces as the "•" character.
vim.opt.listchars:append("multispace:•")

-- Show tabs as the "" character.
vim.opt.listchars:append("tab: ")

-- Show trailing whitespace as the "•" character.
vim.opt.listchars:append("trail:•")

-- The maximum width of text is 79 characters unless otherwise specified.
vim.opt.textwidth = 79

-- Set the window title.
vim.opt.title = true

-- Set the window title to the filename.
vim.opt.titlestring = " 📝  %t"
