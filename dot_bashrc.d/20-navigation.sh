shopt -s autocd dirspell cdspell
CDPATH=":${HOME}:${HOME}/Projects/"

# Keep unique, most-recent-first directory history in this shell only.
# Declaring without assigning preserves history when this file is sourced again.
declare -a _cj_history

_cj_record_directory() {
    local exit_code=$?
    if [[ ${_cj_history[0]-} != "$PWD" ]]; then
        local directory
        local -a history=("$PWD")
        for directory in "${_cj_history[@]}"; do
            [[ $directory == "$PWD" ]] || history+=("$directory")
        done
        _cj_history=("${history[@]}")
    fi
    return "$exit_code"
}

_cj_record_directory
# Preserve the previous command's status for other prompt hooks.
if [[ ${PROMPT_COMMAND-} != *'_cj_record_directory'* ]]; then
    PROMPT_COMMAND="_cj_record_directory${PROMPT_COMMAND:+; ${PROMPT_COMMAND}}"
fi

# Pick a visited directory; cancelling leaves the working directory unchanged.
cj() {
    local directory
    IFS= read -r -d '' directory < <(
        printf '%s\0' "${_cj_history[@]}" |
            command fzf --read0 --print0 --no-multi --no-sort \
                --height=40% --layout=reverse --prompt='Directory> '
    ) || return 0
    builtin cd -- "$directory"
}

# Create a directory and enter it.
mcd() {
    mkdir -p "$1"
    cd "$1"
}

# Enter a temporary directory; -l creates tmp-XXXXXX in the current directory.
# Keep the old directory on the stack; leaving does not remove the temporary one.
cdtmp() {
    local directory
    if (( $# == 0 )); then
        directory=$(command mktemp -d) || return
    elif (( $# == 1 )) && [[ $1 == -l ]]; then
        directory=$(command mktemp -d -- "$PWD/tmp-XXXXXX") || return
    else
        printf 'Usage: cdtmp [-l]\n' >&2
        return 2
    fi
    builtin pushd -- "$directory"
}
