# Keybindings

As the keybindings are defined a little bit all over the place this file
centralize them for me.

## Normal mode
- `,` -> Repeat last : command
- `n` -> Next search result (centered)
- `N` -> Previous search result (centered)
- `<C-d>` -> Half page down (centered)
- `<C-u>` -> Half page up (centered)
- `<A-j>` -> Move line down
- `<A-k>` -> Move line up

## Visual mode
- `<` -> Indent left and reselect
- `>` -> Indent right and reselect
- `<A-j>` -> Move selection down
- `<A-k>` -> Move selection up

## Under `<leader>` (Space)

Every action uses Space followed by one key, with no nested groups.
Window keys mirror stock tmux's prefix bindings; tmux itself is unchanged.

### Window management
- `"` -> Split top/bottom
- `%` -> Split side-by-side
- `o` -> Move to next window
- `x` -> Close this window

### Buffer management
- `n` -> Next buffer
- `p` -> Previous buffer
- `s` -> Open the *scratch* buffer

### Commands
- `c` -> Run a command in the reusable `*command*` buffer
- `r` -> Search file contents with ripgrep in the reusable `*ripgrep*` buffer
- `f` -> List files with ripgrep in the reusable `*files*` buffer

`<leader>l` is intentionally unassigned; use `<leader>c` to run `ls` if needed.

## Native navigation
- `<C-w>h/j/k/l` -> Move left/down/up/right between windows
- `<C-w>o` -> Keep only this window (closes other windows; not a zoom toggle)
- `]b` / `[b` -> Next/previous buffer


<!-- vim: set tw=80 : -->
