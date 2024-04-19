-- Normal mode
vim.keymap.set('n', ',', '@:', { desc = "Repeat last : command", noremap = true })

-- Window management
vim.keymap.set("n", "<leader>wh", "<cmd>split<CR>", { desc = "Create an horizontal split" })
vim.keymap.set("n", "<leader>wv", "<cmd>vsplit<CR>", { desc = "Create a vertical split" })
vim.keymap.set("n", "<leader>wo", "<cmd>only<CR>", { desc = "Keep only this window" })
vim.keymap.set("n", "<leader>wc", "<cmd>close<CR>", { desc = "Close this window" })
