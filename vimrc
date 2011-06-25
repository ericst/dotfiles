""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                                                                                                  "
"                                      Vim configuration file                                      "
"                                                                                                  "
" Author:   Eric Seuret <eric.seuret@gmail.com>                                                    "
" Date:     2011-06-22                                                                             "
"                                                                                                  "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Pathogen {
  call pathogen#runtime_append_all_bundles()
" }

" General {
  set nocompatible                      " Break vi-compatible mode
  set hidden                            " Change buffers without saving
  set fileencoding=utf-8                " Set utf-8 as default file-encoding
  set backspace=indent,eol,start        " Make backspace flexible and work over indent
  set clipboard+=unnamed                " Share windows clipboard
  set noerrorbells                      " No sound on errors
  set mouse=a                           " Mouse everywhere
  filetype plugin indent on             " Load the filetype plugins/indent settings
  syntax on                             " Set Syntax highlighting on
" }

" Vim UI {
  colorscheme desert                    " Set the desert colorscheme
  set cursorline                        " Display the current line
  set laststatus=2                      " Always show the status line
  set hlsearch                          " Highlight search
  set incsearch                         " Incremental search
  set nostartofline                     " Leave my cursor where it was
  set number                            " Turn on line numbers
  set numberwidth=5                     " Allow up to 9999 line
  set scrolloff=10                      " Keep 10 lines (top/bottom) for scope
  set sidescrolloff=5                   " Keep 5 lines (left/right) for scope
  set showcmd                           " Show the command being typed
  set showmatch                         " Show matching brackets
  set statusline=[%04l,%04v][%p%%]\ %f%m%w%q%=%r%y[%{&fileencoding}][%{&ff}]
  "                 |    |    |      | | | |   | |        |             |
  "                 |    |    |      | | | |   | |        |             + End of line type (dos, unix..)
  "                 |    |    |      | | | |   | |        + The encoding of the the file (utf-8, latin1...)            
  "                 |    |    |      | | | |   | + Type of file in the buffer (python, c, vim...)                    
  "                 |    |    |      | | | |   + Readonly flag [RO] if the file is read only                     
  "                 |    |    |      | | | + [Quickfix List] or [Location List] or empty                        
  "                 |    |    |      | | + [Preview] if its a preview buffer                         
  "                 |    |    |      | + Modified flag. [+] for modified, [-] if modifiable is off                          
  "                 |    |    |      + File name in the buffer. Relative to the current working directory                           
  "                 |    |    + Percentage through file in lines                                 
  "                 |    + Column position of the cursor                                     
  "                 + Line position of the cursor
" }

" Text Formatting {
  set expandtab                         " Use space instead of tabs
  set shiftround                        " On tab go to the next tab value, not to the next 5
  set shiftwidth=2                      " Auto-indent amount
  set softtabstop=2                     " How many spaces is a tab
  set tabstop=2                         " Real tabs will be displayed as a 2 spaces
  set smartindent                       " Start smart indent
  set autoindent                        " Start autoindent
" }

" Folding {
  set foldenable                        " Turn on folding
  set foldmarker={,}                    " Fold for C style by default
  set foldmethod=marker                 " Use indent to fold by default
  set foldlevelstart=10                 " Only fold code after level 10 of folding at startup
" }

" GUI Settings {
  if has("gui_running")
    set columns=555                     " Maximize window
    set lines=555                       " Maximize window
    set guioptions-=m                   " Remove menu bar
    set guioptions-=T                   " Remove toolbar
    set guioptions-=r                   " Remove right-hand scroll bar
  endif
" }

" Mappings {
  
  " Moving around {
    " space / shift-space to scroll in normal mode
    noremap <S-Space> <C-b>
    noremap <Space> <C-f>

    " Move arround windows with C-h, even in insert mode
    map <C-h> <C-w>h
    map <C-j> <C-w>j
    map <C-k> <C-w>k
    map <C-l> <C-w>l
    imap <C-h> <Esc><C-w>h
    imap <C-j> <Esc><C-w>j
    imap <C-k> <Esc><C-w>k
    imap <C-l> <Esc><C-w>l

  " }

  " Tags navigation {
    " ét jump to tag, éb jump back
    map ét <C-]>
    map éb <C-T>
  " }

" }

" Abbreviations {
  iabbrev debio Debiotech S.A.
  iabbrev ese Eric Seuret
  iabbrev ydm Yan Demierre
  iabbrev nse Nicolas Serafini
  iabbrev nre Nicolas Renaudot
  iabbrev dv Didier Vecten
  iabbrev pac Pierre-Alain Charmoy
  iabbrev bmi Basile Michelet
  iabbrev ptb Pierre Thiébaud
" }

" Plugins {
  " List of installed plugins:
  "       * supertab
  "       * snipMate
  "       * taglist
  
  " supertab {
    let g:SuperTabDefaultCompletionType = "context"  "Default completion: omnicompletion
  " }

  " taglist {
	  nnoremap <F4> :TlistToggle<CR>
    let Tlist_Use_Right_Window = 1    " Display the taglist on the right of the window
  " }

  " OmniCppComplete {
    " OmniCppComplete
    let OmniCpp_NamespaceSearch = 1
    let OmniCpp_GlobalScopeSearch = 1
    let OmniCpp_ShowAccess = 1
    let OmniCpp_ShowPrototypeInAbbr = 1 " show function parameters
    let OmniCpp_MayCompleteDot = 1 " autocomplete after .
    let OmniCpp_MayCompleteArrow = 1 " autocomplete after ->
    let OmniCpp_MayCompleteScope = 1 " autocomplete after ::
    let OmniCpp_DefaultNamespaces = ["std", "_GLIBCXX_STD"]
    " automatically open and close the popup menu / preview window
    au CursorMovedI,InsertLeave * if pumvisible() == 0|silent! pclose|endif
    set completeopt=menuone,menu,longest,preview
  " }

  " NERDTree {
	  nnoremap <F3> :NERDTreeToggle<CR>
  " }
" }

" Project Management {
  " Simple project management. Specific project settings are set in the
  " vimproject file at root where you open vim.

  if filereadable("vimproject")
    source vimproject
  endif

" }

