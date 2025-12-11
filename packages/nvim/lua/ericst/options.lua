-- Configuration bootstraped with https://github.com/nvim-lua/kickstart.nvim
-- Improved with: https://github.com/radleylewis/nvim-lite/blob/youtube_demo/init.lua

-- Set <space> as the leader key
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Basic Settings
vim.opt.number = true                               -- Line numbers
vim.opt.relativenumber = true                       -- Relative line numbers
vim.opt.cursorline = true                           -- Highlight current line
vim.opt.wrap = false                                -- Don't wrap lines
vim.opt.scrolloff = 5                               -- Keep x lines above/below cursor 
vim.opt.sidescrolloff = 5                           -- Keep x columns left/right of cursor

-- Indentation
vim.opt.tabstop = 4                                 -- Tab width
vim.opt.shiftwidth = 4                              -- Indent width
vim.opt.softtabstop = 4                             -- Soft tab stop
vim.opt.expandtab = true                            -- Use spaces instead of tabs
vim.opt.smartindent = true                          -- Smart auto-indenting
vim.opt.autoindent = true                           -- Copy indent from current line
vim.g.editorconfig = true                           -- Follow editor config file if present

-- Search settings
vim.opt.ignorecase = true                           -- Case insensitive search
vim.opt.smartcase = true                            -- Case sensitive if uppercase or \C in search
vim.opt.hlsearch = false                            -- Don't highlight search results 
vim.opt.incsearch = true                            -- Show matches as you type

-- Visual settings
vim.opt.termguicolors = true                        -- Enable 24-bit colors
vim.opt.signcolumn = "yes"                          -- Always show sign column
vim.opt.showmatch = true                            -- Highlight matching brackets
vim.opt.cmdheight = 1                               -- Command line height
vim.opt.completeopt = "menuone,noinsert,popup,fuzzy"-- Completion options 
vim.opt.pumheight = 0                               -- Popup menu height, as heigh as possible
vim.opt.winborder = "rounded"                       -- Nice windows for the menus

-- File handling
vim.opt.backup = false                              -- Don't create backup files
vim.opt.writebackup = false                         -- Don't create backup before writing
vim.opt.swapfile = false                            -- Don't create swap files
vim.opt.undofile = true                             -- Persistent undo
vim.opt.undodir = vim.fn.expand("~/.vim/undodir")   -- Undo directory
vim.opt.autoread = true                             -- Auto reload files changed outside vim
vim.opt.autowrite = false                           -- Don't auto save
vim.opt.path:append("**")                           -- include subdirectories in search

-- Behavior settings
vim.opt.hidden = true                               -- Allow hidden buffers
vim.opt.errorbells = false                          -- No error bells
vim.opt.iskeyword:append("-")                       -- Treat dash as part of word
vim.opt.mouse = "a"                                 -- Enable mouse support
vim.opt.timeoutlen = 5000                           -- Key timeout duration

-- Command-line completion
vim.opt.wildmenu = true                             -- I want the wildmenu in command line
vim.opt.wildmode = "full"                           -- No select, keep my command as is for the moment.

-- Folding settings
vim.opt.foldmethod = 'indent'                       -- Use indent, local settings still possible
vim.opt.foldlevel = 99                              -- Start with folds open

-- Split behavior
vim.opt.splitbelow = true                           -- Horizontal splits go below
vim.opt.splitright = true                           -- Vertical splits go right

--- NetRW Configuration
vim.g.netrw_banner = 0                              -- Suppress the banner
vim.g.netrw_liststyle = 3                           -- Tree style listing
vim.g.netrw_browse_split = 4                        -- When browsing <cr> opens in prev. window.

-- Highlight on yank
-- See `:help vim.highlight.on_yank()`
local highlight_group = vim.api.nvim_create_augroup('YankHighlight', { clear = true })
vim.api.nvim_create_autocmd('TextYankPost', {
  callback = function()
    vim.highlight.on_yank()
  end,
  group = highlight_group,
  pattern = '*',
})

-- Setting the rg as grep program
vim.opt.grepprg="rg --vimgrep"

-- Open the quickfix list after running a grep comand
vim.api.nvim_create_autocmd("QuickFixCmdPost", {
  pattern = "*grep*",
  callback = function()
    vim.cmd("cwindow")
  end,
})


