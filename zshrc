#
# Executes commands at the start of an interactive session.
#
# Authors:
#   Eric Seuret <eric.seuret@gmail.com>
#   Sorin Ionescu <sorin.ionescu@gmail.com>
#

# Source Prezto.
if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi


##################################################
#### Aliases
##################################################
# When you forget the sudo (stp = please in french)
alias stp='sudo $(fc -ln -1)'


##################################################
#### Variables
##################################################
export EDITOR="vim"
export VISUAL=$EDITOR



