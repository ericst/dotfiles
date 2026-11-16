# Keep home directories first, /usr/local before /usr, and custom paths last.
# Drop missing directories and duplicates, including trailing-slash variants.
rebuild_path() {
    local new_path="" seen="" dir

    _path_add() {
        local d="${1%/}"
        [ -d "$d" ] || return
        [[ ":$seen:" == *":$d:"* ]] && return
        new_path="${new_path:+$new_path:}$d"
        seen="${seen:+$seen:}$d"
    }

    local IFS=:
    for dir in $PATH; do
        dir="${dir%/}"
        [[ "$dir" == "$HOME"* ]] && _path_add "$dir"
    done

    _path_add /usr/local/sbin
    _path_add /usr/local/bin
    _path_add /usr/sbin
    _path_add /usr/bin
    _path_add /usr/lib64/ccache
    _path_add /sbin
    _path_add /bin

    for dir in $PATH; do
        _path_add "$dir"
    done

    PATH="$new_path"
    unset -f _path_add
}

if [ -d "$HOME/.local/bin" ] && [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    PATH="$HOME/.local/bin:$PATH"
fi

rebuild_path
export PATH
