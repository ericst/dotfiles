#
# Executes commands at the start of an interactive session.
#
# Authors:
#   Eric Seuret <eric.seuret@gmail.com>
#

##################################################
#### zplug 
##################################################

# Check if zplug is installed
if [[ ! -d ~/.zplug ]]; then
  git clone https://github.com/zplug/zplug ~/.zplug
  source ~/.zplug/init.zsh && zplug update --self
fi

# Essential
source ~/.zplug/init.zsh


# Async for zsh, used by pure
zplug "mafredri/zsh-async", from:github, defer:0

# Load completion library for those sweet [tab] squares
zplug "lib/completion", from:oh-my-zsh

# Up -> History search! Who knew it wasn't a built in?
zplug "lib/key-bindings", from:oh-my-zsh

# History defaults
zplug "lib/history", from:oh-my-zsh

# gst, gco, gc -> All the git shortcut goodness
zplug "plugins/git", from:oh-my-zsh, if:"hash git"

# Syntax highlighting for commands
zplug "zsh-users/zsh-syntax-highlighting", from:github, defer:3

# Theme!
zplug "themes/ys", from:oh-my-zsh


# Install packages that have not been installed yet
if ! zplug check --verbose; then
    printf "Install? [y/N]: "
    if read -q; then
        echo; zplug install
    else
        echo
    fi
fi

zplug load


##################################################
#### Aliases
##################################################
# When you forget the sudo (stp = please in french)
alias stp='sudo $(fc -ln -1)'
alias emax='emacsclient -c -na emacs'


##################################################
#### Variables
##################################################
export EDITOR="nvim"
export VISUAL=$EDITOR
export SSH_AUTH_SOCK=/run/user/1000/gnupg/S.gpg-agent.ssh

##################################################
#### Environments
##################################################
if [ -f "$HOME/.cargo/env" ]; then
    source "$HOME/.cargo/env"
fi
