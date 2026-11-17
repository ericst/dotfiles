-- Normal mode
vim.keymap.set('n', ',', '@:', { desc = "Repeat last : command", noremap = true })

-- Window management
-- Match stock tmux's split, close, and next-pane keys.
vim.keymap.set("n", '<Leader>"', "<Cmd>split<CR>", { desc = "Split top/bottom" })
vim.keymap.set("n", "<Leader>%", "<Cmd>vsplit<CR>", { desc = "Split side-by-side" })
vim.keymap.set("n", "<Leader>x", "<Cmd>close<CR>", { desc = "Close this window" })
vim.keymap.set("n", "<Leader>o", "<C-w>w", { desc = "Move to next window" })
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
vim.keymap.set("n", "<Leader>n", "<Cmd>bnext<CR>", { desc = "Next buffer" })
vim.keymap.set("n", "<Leader>p", "<Cmd>bprevious<CR>", { desc = "Previous buffer" })
vim.keymap.set("n", "<Leader>s", ese_scratch, { desc = "Open the *scratch* buffer" })

-- Commands
-- Open a buffer with command results.
vim.keymap.set("n", "<Leader>c", function() ese_command(nil, "*command*") end, { desc = "Run a command in the command buffer" })
vim.keymap.set("n", "<Leader>r", function() ese_command("rg --follow --vimgrep --smart-case ", "*ripgrep*") end, { desc = "Quick view: ripgrep through files" })
vim.keymap.set("n", "<Leader>f", function() ese_command("rg --follow --files ", "*files*") end, { desc = "Quick view: ripgrep files" })


-- Center screen when jumping
vim.keymap.set("n", "n", "nzzzv", { desc = "Next search result (centered)" })
vim.keymap.set("n", "N", "Nzzzv", { desc = "Previous search result (centered)" })
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Half page down (centered)" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Half page up (centered)" })

