export GUIX_PROFILE="$HOME/.guix-profile"
export GUIX_LOCPATH="$GUIX_PROFILE/lib/locale"
if [ -e "$GUIX_PROFILE/etc/profile"  ]; then
    source "$GUIX_PROFILE/etc/profile"
fi

if [ -f /etc/profile ]; then
    source /etc/profile;
fi

if [ -f ~/.bashrc ]; then
    source ~/.bashrc;
fi

export PATH="$HOME/bin:$PATH"
