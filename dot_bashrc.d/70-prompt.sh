_git_prompt=/usr/share/git-core/contrib/completion/git-prompt.sh
[ -f "$_git_prompt" ] && source "$_git_prompt"
GIT_PS1_SHOWDIRTYSTATE=1
GIT_PS1_SHOWUNTRACKEDFILES=1

_build_ps1() {
    local exit_code=$?  # Must be first.
    local G='\[\e[1;32m\]' R='\[\e[0m\]' E='\[\e[1;31m\]'

    local container=""
    [ -n "$CONTAINER_ID" ] && container="[${CONTAINER_ID}] "

    # Show running and stopped job counts only when there are jobs.
    local running stopped jobs_str=""
    running=$(jobs -r -p | wc -l)
    stopped=$(jobs -s -p | wc -l)
    if [ "$running" -gt 0 ] || [ "$stopped" -gt 0 ]; then
        local inner=""
        [ "$running" -gt 0 ] && inner+="${running}r"
        [ "$stopped" -gt 0 ] && inner+="${stopped}s"
        jobs_str="{${inner}} "
    fi

    local git=""
    declare -f __git_ps1 &>/dev/null && {
        local b; b=$(__git_ps1 "%s")
        [ -n "$b" ] && git=" (${b})"
    }

    local exit_str=""
    [ "$exit_code" -ne 0 ] && exit_str="${E}${exit_code}${R} "

    PS1="${G}${jobs_str}${container}\u@\h \w${git} ${R}\n${exit_str}\$ "
}

# Build the prompt before the history hook so it sees the command's exit status.
PROMPT_COMMAND="_build_ps1${PROMPT_COMMAND:+; ${PROMPT_COMMAND}}"
