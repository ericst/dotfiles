# ericst's dotfiles

Personal dotfiles managed with [chezmoi](https://www.chezmoi.io/), using its
conventional source-state layout. There is no package-selection layer or custom
installer.

## Layout

```text
dot_bashrc                         -> ~/.bashrc
dot_bashrc.d/                      -> ~/.bashrc.d/
dot_config/                       -> ~/.config/
dot_gitconfig                     -> ~/.gitconfig
dot_inputrc                       -> ~/.inputrc
dot_XCompose                      -> ~/.XCompose
dot_tmux.conf                     -> ~/.tmux.conf
private_dot_local/                -> ~/.local/
```

All managed files and directories are installed as regular files and directories,
including `dot_config/nvim/lua/` and `dot_config/nvim/ftplugin/`. No symlink-backed
configuration is needed.

The `executable_` attribute installs the repository checker as an executable.
The `private_` attributes preserve private permissions on `~/.local`,
`~/.local/share`, and `~/.local/share/applications`. Shared directories are not
marked `exact_`, so unrelated local files are left alone. `.chezmoiignore` keeps
repository documentation out of the destination.

## Preview and apply

Install chezmoi separately first. Bash configuration requires Bash 4 or newer.
There are no chezmoi package-installation or apply scripts.

From this checkout, preview the migration without applying it:

```sh
chezmoi --source "$PWD" --working-tree "$PWD" diff
chezmoi --source "$PWD" --working-tree "$PWD" apply --dry-run --verbose
```

Once the preview is approved, initialize chezmoi to use this checkout. This writes
its configuration but does not apply the dotfiles:

```sh
chezmoi --source "$PWD" --working-tree "$PWD" init
```

The config template remembers the selected source directory. Review once more,
then apply interactively:

```sh
chezmoi diff
chezmoi apply --interactive
```

Applying replaces managed legacy symlinks with regular files and directories,
including Neovim's `lua` and `ftplugin` directories. It does not remove the old
checkout, unmanaged files, or previously installed opencode configuration.
Review and remove those separately after checking that no remaining symlinks
depend on the old checkout.

The package layout, Python/Ruby installers, and opencode sources have been
removed. The Taskwarrior shell alias is included, as specified by its former
installer, even if it was not previously installed on a particular machine.

## Bash modules

`dot_bashrc` only resets inherited prompt hooks, loads `/etc/bashrc`, and sources
readable files directly inside `~/.bashrc.d` in filename order. Subdirectories
are not sourced automatically.

| Module in `dot_bashrc.d/` | Functionality |
| --- | --- |
| `10-history.sh` | History settings and immediate history saving |
| `20-navigation.sh` | Directory completion, `mcd`, and `cdtmp` |
| `30-aliases.sh` | Safety and general-purpose aliases |
| `40-editor.sh` | Editor variables, aliases, and man pager |
| `50-repository-check.sh` | Interactive repository-status check |
| `60-containers.sh` | Distrobox `workbox` helper and Podman aliases |
| `70-prompt.sh` | Git, jobs, container, and exit-status prompt |
| `80-path.sh` | PATH ordering and deduplication |
| `bgjobs` | Background-job helpers |
| `git` | Git aliases |
| `taskwarrior` | Taskwarrior inbox alias |
| `toolbox.rc` | Toolbox first-run setup |
| `toolboxes/workbox.rc` | Software installed by the workbox Toolbox setup |
| `zig` | Zig standard-library discovery |
| `zz-ghostty.sh` | Ghostty integration, after the other tracked modules |

Toolbox's existing automatic software installation is deliberately retained.
Sourcing Bash configuration inside a fresh Toolbox can therefore run `sudo dnf`
and create `/.first_run`. The repository checker can fetch Git remotes and write
its cache. Neither behavior runs merely from chezmoi applying the configuration.

Name additional local modules so they sort before `zz-ghostty.sh` if Ghostty
integration should remain last. Existing local modules are not removed.

## Editing

For regular managed files, use the standard chezmoi workflow:

```sh
chezmoi edit ~/.bashrc
chezmoi diff
chezmoi apply
```

You can also edit the corresponding source files directly, then run
`chezmoi apply`. Use `chezmoi add ~/.config/example/config` to manage a new file,
or `chezmoi re-add` to capture changes made directly to installed regular files.

Neovim uses the same workflow: edit files under `dot_config/nvim/` and apply,
or use `chezmoi edit` on their installed paths. Add new configuration files with
`chezmoi add`.

See [tmux notes](docs/tmux.md) for the GNOME Alt-Space adjustment.
