
vim.cmd [[set tags="./tags,tags" ]] -- Somehow vim.opt.tags deosn't work

-- Automatically create tags files on save.
vim.api.nvim_create_autocmd({"BufWritePost"}, {
  pattern = {"*.c", "*.cpp", "*.zig", "*.py"}, -- Add file types you want to track
  command = "!ctags -R .",
})
