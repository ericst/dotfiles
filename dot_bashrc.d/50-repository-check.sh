# Check repository status only in interactive shells.
if [[ $- == *i* ]]; then
    timeout 5 "$HOME/.local/bin/dotfiles-git-check"
fi
