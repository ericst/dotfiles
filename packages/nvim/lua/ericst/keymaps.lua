-- Normal mode
vim.keymap.set('n', ',', '@:', { desc = "Repeat last : command", noremap = true })

-- Window management
vim.keymap.set("n", "<Leader>s", "<Cmd>split<CR>", { desc = "Create an horizontal split" })
vim.keymap.set("n", "<Leader>v", "<Cmd>vsplit<CR>", { desc = "Create a vertical split" })
vim.keymap.set("n", "<Leader>f", "<Cmd>only<CR>", { desc = "Focus on this window" })
vim.keymap.set("n", "<Leader>c", "<Cmd>close<CR>", { desc = "Close this window" })
vim.keymap.set("n", "<Leader>o", "<C-w>w", { desc = "Move to to other window" })
vim.keymap.set("n", "<Leader>gh", "<C-w>h", { desc = "Move to left window" })
vim.keymap.set("n", "<Leader>gj", "<C-w>j", { desc = "Move to bottom window" })
vim.keymap.set("n", "<Leader>gk", "<C-w>k", { desc = "Move to top window" })
vim.keymap.set("n", "<Leader>gl", "<C-w>l", { desc = "Move to right window" })
--TODO: Improve netrw opening, maybe give it 15 cols right or something

-- Move lines up/down
vim.keymap.set("n", "<A-k>", "<Cmd>m .-2<CR>==", { desc = "Move line up" })
vim.keymap.set("n", "<A-j>", "<Cmd>m .+1<CR>==", { desc = "Move line down" })
vim.keymap.set("v", "<A-j>", "<Cmd>m '>+1<CR>gv=gv", { desc = "Move selection down" })
vim.keymap.set("v", "<A-k>", "<Cmd>m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- Better indenting in visual mode
vim.keymap.set("v", "<", "<gv", { desc = "Indent left and reselect" })
vim.keymap.set("v", ">", ">gv", { desc = "Indent right and reselect" })

-- Buffers
-- The first two are redundant with ]b and [b but are here for consistancy
vim.keymap.set("n", "<Leader>bn", "<Cmd>bnext<CR>", { desc = "Next buffer" })
vim.keymap.set("n", "<Leader>bp", "<Cmd>bprevious<CR>", { desc = "Previous buffer" })
vim.keymap.set("n", "<Leader>bs", ese_scratch, { desc = "Open the *scratch* buffer" })

-- Commands
-- Open a buffer with commands reseult
vim.keymap.set("n", "<Leader>bc", function() ese_command() end, { desc = "Run a command in a temp buffer" })
vim.keymap.set("n", "<Leader>br", function() ese_command("rg --follow --vimgrep ") end, { desc = "Quick view: ripgrep through files" })
vim.keymap.set("n", "<Leader>bf", function() ese_command("rg --follow --files ") end, { desc = "Quick view: ripgrep files" })
vim.keymap.set("n", "<Leader>bl", function() ese_command("ls -la ") end, { desc = "Quick view: directory listing" })


-- Center screen when jumping
vim.keymap.set("n", "n", "nzzzv", { desc = "Next search result (centered)" })
vim.keymap.set("n", "N", "Nzzzv", { desc = "Previous search result (centered)" })
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Half page down (centered)" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Half page up (centered)" })

