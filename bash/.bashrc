[[ $- == *i* ]] && stty -ixon

shopt -s histappend
HISTFILESIZE=1000000
HISTSIZE=1000000

HISTCONTROL=ignoreboth
export HISTIGNORE="exit:ls:bg:fg:jobs:history"

HISTTIMEFORMAT='%F %T '

alias hs="history | grep"

shopt -s autocd
shopt -s dirspell
shopt -s cdspell

CDPATH=".:~/projects"
shopt -s cdable_vars

dotfiles="$HOME/dotfiles/"
documents="$HOME/Documents/"
downloads="$HOME/Downloads/"
exocortex="$HOME/exocortex/"

update_prompt (){
    local return_code=$?

    # The user name, host & host
    PS1='\u@\h \W '


    #Guix environment, if present
    if [ -n "$GUIX_ENVIRONMENT" ]; then
        PS1+='[dev]'
    fi

    # The return code if present
    if [ $return_code != 0 ]; then
        PS1+="(${return_code})"
    fi

    #Prompt
    PS1+='\$ '  
}

PROMPT_COMMAND=update_prompt

alias rm='rm -I --preserve-root'

alias mv='mv -i'
alias cp='cp -i'
alias ln='ln -i'

alias chown='chown --preserve-root'
alias chmod='chmod --preserve-root'
alias chgrp='chgrp --preserve-root'

export ALTERNATE_EDITOR=""
export EDITOR="emacsclient -ta \"emacs -nw\""
export VISUAL="emacsclient -na \"emacs"\"
export GIT_EDITOR="$EDITOR"
alias e="$VISUAL"
alias et="$EDITOR"

alias ls="ls --color=auto"
alias lsl="ls --color=auto | less"
alias ll="ls --color=auto -lh"
alias lll="ls --color=auto -lh | less"
alias l.="ls --color=auto -d .*"
alias l.l="ls --color=auto -d .* | less"

alias grep='grep --color=auto'

alias ps="ps auxf"
alias psl="ps auxf | less"

alias psg="ps aux | grep -v grep | \grep -i -e VSZ -e"

alias mkdir="mkdir -pv"

mcd () {
    mkdir -p $1
    cd $1
}
