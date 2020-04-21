# Eric Seuret's zsh configuration


## Help emacs' tramp mode when needed.
[[ $TERM == "dumb" ]] && unsetopt zle && PROMPT='$ ' && return

## Case insensitive globbing
setopt NO_CASE_GLOB

## Automatically change directory without cd
setopt AUTO_CD

## History options (some may be redundant here)
HISTFILE=${ZDOTDIR:-$HOME}/.zsh_history
setopt EXTENDED_HISTORY
SAVEHIST=5000
HISTSIZE=2000
setopt SHARE_HISTORY
setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_REDUCE_BLANKS

## Corrections
setopt CORRECT
setopt CORRECT_ALL

## TAB completions
autoload -Uz compinit && compinit

### Case Insensitive Path Completion
zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]} l:|=* r:|=*' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]} l:|=* r:|=*' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]} l:|=* r:|=*'

### Partial completion (/u/lo/bi -> /usr/local/bin)
zstyle ':completion:*' list-suffixes
zstyle ':completion:*' expand prefix suffix

### Use bash completions if no zsh are available
autoload bashcompinit && bashcompinit

## Prompt
PROMPT='%(?..%F{red}%? %f)%n@%m %1~ %# '

### Git integration on rightprompt
autoload -Uz vcs_info
precmd_vcs_info() { vcs_info }
precmd_functions+=( precmd_vcs_info )
setopt prompt_subst
RPROMPT=\$vcs_info_msg_0_
zstyle ':vcs_info:git:*' formats '(%b)%r'
zstyle ':vcs_info:*' enable git

## Emacs editor
export ALTERNATE_EDITOR=""
export EDITOR="emacsclient -t"               # $EDITOR opens in terminal
export VISUAL="emacsclient -a emacs"         # $VISUAL opens in GUI mode
export GIT_EDITOR="emacsclient -t"

## Guix
export GUIX_PROFILE="$HOME/.guix-profile"
export GUIX_LOCPATH="$GUIX_PROFILE/lib/locale"
if [ -e "$GUIX_PROFILE/etc/profile"  ]; then
    source "$GUIX_PROFILE/etc/profile"
fi
export GUIX_PACKAGE_PATH="$HOME/git/ericst-guix/"


## Aliases
alias stow='stow --no-folding'
alias e="$VISUAL"
alias et="$EDITOR"
