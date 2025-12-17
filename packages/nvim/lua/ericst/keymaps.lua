-- Normal mode
vim.keymap.set('n', ',', '@:', { desc = "Repeat last : command", noremap = true })

-- Window management
vim.keymap.set("n", "<Leader>ws", "<Cmd>split<CR>", { desc = "Create an horizontal split" })
vim.keymap.set("n", "<Leader>wv", "<Cmd>vsplit<CR>", { desc = "Create a vertical split" })
vim.keymap.set("n", "<Leader>wf", "<Cmd>only<CR>", { desc = "Focus on this window" })
vim.keymap.set("n", "<Leader>wc", "<Cmd>close<CR>", { desc = "Close this window" })
vim.keymap.set("n", "<Leader>wh", "<C-w>h", { desc = "Move to left window" })
vim.keymap.set("n", "<Leader>wj", "<C-w>j", { desc = "Move to bottom window" })
vim.keymap.set("n", "<Leader>wk", "<C-w>k", { desc = "Move to top window" })
vim.keymap.set("n", "<Leader>wl", "<C-w>l", { desc = "Move to right window" })
vim.keymap.set("n", "<Leader>wo", "<C-w>w", { desc = "Move to to other window" })
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
vim.keymap.set("n", "<Leader>bb", ":Pick buffers<CR>", { desc = "Find buffer by name" })
vim.keymap.set("n", "<Leader>bs", function() ese_create_or_switch_scratch_buffer("*scratch*") end, { desc = "Open the *scratch* buffer" })
vim.keymap.set("n", "<Leader>bj", function() ese_create_or_switch_autosave_buffer("~/journal.md") end , { desc = "Open global journal" })

-- Harpoon
-- It actually is a really good way of working with buffers...
local harpoon = require("harpoon")
harpoon:setup()
vim.keymap.set("n", "<Leader>H", function() harpoon:list():add()  end , { desc = "Add the buffer to the harpoon list" })
vim.keymap.set("n", "<Leader>h", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end , { desc = "Open the harpoon list" })
vim.keymap.set("n", "<Leader>1", function() harpoon:list():select(1) end , { desc = "Open buffer 1 in harpoon list" })
vim.keymap.set("n", "<Leader>2", function() harpoon:list():select(2) end , { desc = "Open buffer 2 in harpoon list" })
vim.keymap.set("n", "<Leader>3", function() harpoon:list():select(3) end , { desc = "Open buffer 3 in harpoon list" })
vim.keymap.set("n", "<Leader>4", function() harpoon:list():select(4) end , { desc = "Open buffer 4 in harpoon list" })
vim.keymap.set("n", "<Leader>5", function() harpoon:list():select(5) end , { desc = "Open buffer 5 in harpoon list" })
vim.keymap.set("n", "<Leader>6", function() harpoon:list():select(6) end , { desc = "Open buffer 6 in harpoon list" })
vim.keymap.set("n", "<Leader>7", function() harpoon:list():select(7) end , { desc = "Open buffer 7 in harpoon list" })
vim.keymap.set("n", "<Leader>8", function() harpoon:list():select(8) end , { desc = "Open buffer 8 in harpoon list" })
vim.keymap.set("n", "<Leader>9", function() harpoon:list():select(9) end , { desc = "Open buffer 9 in harpoon list" })


-- Center screen when jumping
vim.keymap.set("n", "n", "nzzzv", { desc = "Next search result (centered)" })
vim.keymap.set("n", "N", "Nzzzv", { desc = "Previous search result (centered)" })
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Half page down (centered)" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Half page up (centered)" })

-- Find stuff
vim.keymap.set("n", "<Leader>ff", ":Pick files<CR>", { desc = "Find files by name" })
vim.keymap.set("n", "<Leader>fh", ":Pick help<CR>", { desc = "Find files by name" })
vim.keymap.set("n", "<Leader>fb", ":Pick buffers<CR>", { desc = "Find buffer by name" })
vim.keymap.set("n", "<Leader>fg", ":grep ", { desc = "Grep files" })
vim.keymap.set("n", "<Leader>fw", ":grep <cword>", { desc = "Grep files for word under the cursor" })

-- Auto complete
vim.keymap.set("i", "<C-l>", "<C-x><C-l>", { desc = "Line completion" })
vim.keymap.set('i', "<C-/>", '<C-y><C-x><C-f>', { desc = 'Accept path and restart completion' })
