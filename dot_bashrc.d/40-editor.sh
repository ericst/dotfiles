export ALTERNATE_EDITOR="vi"
export EDITOR="nvim"
export VISUAL="nvim"
export GIT_EDITOR="$EDITOR"
alias e="$VISUAL"

if type nvim &> /dev/null; then
    alias vim='nvim'
    export MANPAGER='nvim +Man!'
fi
