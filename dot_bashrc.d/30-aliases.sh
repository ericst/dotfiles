# Confirm destructive operations and protect the filesystem root.
alias rm='rm -I --preserve-root'
alias mv='mv -i'
alias cp='cp -i'
alias ln='ln -i'
alias chown='chown --preserve-root'
alias chmod='chmod --preserve-root'
alias chgrp='chgrp --preserve-root'

alias grep='grep --color=auto'
alias psa='ps auxf'
alias psg='pgrep -afi'
alias md='mkdir -pv'
alias o='xdg-open'

# Filesystem capacity and one-level directory usage.
alias dfh='df -hT'
alias duh='du -h --max-depth=1'

alias ll="ls -lish"
alias la="ls -lisah"
