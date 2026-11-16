# Append large, timestamped histories, keeping multiline commands together.
# https://sanctum.geek.nz/arabesque/better-bash-history/
shopt -s histappend cmdhist lithist histverify
HISTFILESIZE=1000000
HISTSIZE=1000000
HISTCONTROL=ignoreboth
export HISTIGNORE="exit:ls:bg:fg:jobs:history"
HISTTIMEFORMAT='%F %T '

# Save every command immediately rather than waiting for shell exit.
PROMPT_COMMAND="history -a; $PROMPT_COMMAND"
alias hs="history | grep"
