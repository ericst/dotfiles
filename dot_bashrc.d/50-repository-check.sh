# Check local chezmoi differences only in interactive shells.
if [[ $- == *i* ]] && command -v chezmoi >/dev/null 2>&1; then
    (
        if status=$(timeout 5 chezmoi --refresh-externals=never --no-tty --no-pager --color=false status); then
            if [[ -n "$status" ]]; then
                printf 'chezmoi: Managed files differ from the desired state:\n%s\n' "$status"
                printf 'Review with `chezmoi diff` before applying or re-adding changes.\n'
            fi
        else
            printf 'chezmoi: Status check failed or timed out; run `chezmoi status` manually.\n' >&2
        fi
    )
fi
