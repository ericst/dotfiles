shopt -s autocd dirspell cdspell
CDPATH=":${HOME}:${HOME}/Projects/"

# Create a directory and enter it.
mcd() {
    mkdir -p "$1"
    cd "$1"
}

# Enter a new temporary directory, keeping the old one on the directory stack.
cdtmp() {
    pushd "$(mktemp -d)"
}
