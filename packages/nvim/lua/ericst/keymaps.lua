-- Normal mode
vim.keymap.set('n', ',', '@:', { desc = "Repeat last : command", noremap = true })

-- Window management
vim.keymap.set("n", "<LEADER>ws", "<CMD>split<CR>", { desc = "Create an horizontal split" })
vim.keymap.set("n", "<LEADER>wv", "<CMD>vsplit<CR>", { desc = "Create a vertical split" })
vim.keymap.set("n", "<LEADER>wo", "<CMD>only<CR>", { desc = "Keep only this window" })
vim.keymap.set("n", "<LEADER>wc", "<CMD>close<CR>", { desc = "Close this window" })
vim.keymap.set("n", "<LEADER>wh", "<C-w>h", { desc = "Move to left window" })
vim.keymap.set("n", "<LEADER>wj", "<C-w>j", { desc = "Move to bottom window" })
vim.keymap.set("n", "<LEADER>wk", "<C-w>k", { desc = "Move to top window" })
vim.keymap.set("n", "<LEADER>wl", "<C-w>l", { desc = "Move to right window" })
--TODO: Improve netrw opening, maybe give it 15 cols right or something

-- Move lines up/down
vim.keymap.set("n", "<A-k>", "<CMD>m .-2<CR>==", { desc = "Move line up" })
vim.keymap.set("n", "<A-j>", "<CMD>m .+1<CR>==", { desc = "Move line down" })
vim.keymap.set("v", "<A-j>", "<CMD>m '>+1<CR>gv=gv", { desc = "Move selection down" })
vim.keymap.set("v", "<A-k>", "<CMD>m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- Better indenting in visual mode
vim.keymap.set("v", "<", "<gv", { desc = "Indent left and reselect" })
vim.keymap.set("v", ">", ">gv", { desc = "Indent right and reselect" })

-- Buffers
-- The first two are redundant with ]b and [b but are here for consistancy
vim.keymap.set("n", "<LEADER>bn", "<CMD>bnext<CR>", { desc = "Next buffer" })
vim.keymap.set("n", "<LEADER>bp", "<CMD>bprevious<CR>", { desc = "Previous buffer" })
vim.keymap.set("n", "<LEADER>bb", "<CMD>buffers<CR>:b ", { desc = "Previous buffer" })
vim.keymap.set("n", "<LEADER>bs", function() create_or_switch_scratch_buffer("*scratch*") end, { desc = "Open the *scratch* buffer" })
vim.keymap.set("n", "<LEADER>bj", function() create_or_switch_autosave_buffer("~/journal.md") end , { desc = "Open global journal" })

-- Center screen when jumping
vim.keymap.set("n", "n", "nzzzv", { desc = "Next search result (centered)" })
vim.keymap.set("n", "N", "Nzzzv", { desc = "Previous search result (centered)" })
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Half page down (centered)" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Half page up (centered)" })
