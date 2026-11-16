# Load after the prompt and other tracked modules, including inside Distrobox.
# Use installed resources, never the old resource cache.
if [[ $- == *i* && ${TERM_PROGRAM:-} == ghostty ]]; then
    for _ghostty_resources in \
        "${GHOSTTY_RESOURCES_DIR:-}" \
        /usr/local/share/ghostty \
        /usr/share/ghostty \
        /run/host/usr/local/share/ghostty \
        /run/host/usr/share/ghostty; do
        _ghostty_resources=${_ghostty_resources%/}
        [[ -n $_ghostty_resources ]] || continue
        [[ $_ghostty_resources == "$HOME/.cache/ghostty/resources-copy" ]] && continue
        if [[ -r $_ghostty_resources/shell-integration/bash/ghostty.bash ]]; then
            export GHOSTTY_RESOURCES_DIR="$_ghostty_resources"
            builtin source "$_ghostty_resources/shell-integration/bash/ghostty.bash"
            break
        fi
    done
    unset _ghostty_resources
fi
