-- Configuration bootstraped with https://github.com/nvim-lua/kickstart.nvim

-- Set <space> as the leader key
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Configure nvim itself
-- Tabs if sleuth doesn't work (see plugins/diverse.lua for more info)
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

-- Set highlight on search
vim.o.hlsearch = false

-- Make line numbers default
vim.wo.number = true
vim.wo.relativenumber = true

-- Highlight cursorline
vim.o.cursorline = true

-- Enable mouse mode
vim.o.mouse = 'a'

-- History and swap files
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = vim.fn.stdpath("data") .. "/undodir"
vim.opt.undofile = true

-- Case-insensitive searching UNLESS \C or capital in search
vim.o.ignorecase = true
vim.o.smartcase = true


-- Decrease update time
vim.o.updatetime = 250

-- Explicitly set wait time for key sequences
vim.o.timeoutlen = 5000

-- NOTE: You should make sure your terminal supports this
vim.o.termguicolors = true


-- [[ Highlight on yank ]]
-- See `:help vim.highlight.on_yank()`
local highlight_group = vim.api.nvim_create_augroup('YankHighlight', { clear = true })
vim.api.nvim_create_autocmd('TextYankPost', {
  callback = function()
    vim.highlight.on_yank()
  end,
  group = highlight_group,
  pattern = '*',
})

-- Indentation should follow synthax
vim.opt.smartindent = true

-- Always keep a little bit of context top and bottom
vim.opt.scrolloff = 10

-- Set foldmethod by defaut to indent 
vim.opt.foldmethod = 'indent'
vim.opt.foldlevel = 10

-- Sync clipboard between OS and Neovim.
--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
vim.o.clipboard = 'unnamedplus'

--- NetRW Configuration
vim.g.netrw_banner = 0
vim.g.netrw_liststyle = 3
vim.g.netrw_browse_split = 4
vim.g.netrw_altv = 1
vim.g.netrw_winsize = 25

-- vim: ts=2 sts=2 sw=2 et ft=lua
