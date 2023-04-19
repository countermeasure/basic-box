-- Remove trailing whitespace on save.
vim.api.nvim_create_autocmd({ "BufWritePre" }, {
  callback = function()
    local view = vim.fn.winsaveview()
    vim.cmd("keeppatterns %s/\\s\\+$//e")
    vim.fn.winrestview(view)
  end,
  pattern = "*",
})

-- Set the ruler to 89 for Python files.
vim.api.nvim_create_autocmd("FileType", {
  callback = function()
    vim.opt_local.colorcolumn = "89"
  end,
  pattern = "python",
})
