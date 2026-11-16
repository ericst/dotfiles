export ALTERNATE_EDITOR="vi"
export EDITOR="nvim"
export VISUAL="nvim"
export GIT_EDITOR="$EDITOR"
alias e="$VISUAL"

if type -P nvim &> /dev/null; then
    alias vi='nvim'
    alias vim='nvim'
    export MANPAGER='nvim +Man!'
elif type -P vim &> /dev/null; then
    alias vi='vim'
fi
