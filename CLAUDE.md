# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a personal dotfiles repository managed through Ruby scripts. The system creates symlinks from configuration files in this repository to their expected locations in the user's home directory.

## Core Commands

### Installing packages
```bash
./dotfiles.rb [options] packages...
```
- Install specific packages: `./dotfiles.rb git nvim essential`
- Force installation (overwrite existing files): `./dotfiles.rb -f essential`

### Available packages
- `essential` - Core shell configuration (bashrc, inputrc, toolbox setup)
- `git` - Git configuration
- `nvim` - Neovim configuration with Lua plugins
- `ghostty` - Ghostty terminal emulator configuration
- `wezterm` - WezTerm terminal emulator configuration

## Architecture

### Package System
Each package is a directory under `packages/` containing:
- `install.rb` - Installation script that defines symlinks using the `link` function
- Configuration files to be linked to the home directory

### Core Functions (dotfiles.rb)
- `install_package(package)` - Loads and executes a package's install.rb
- `link(to, from)` - Creates symlinks with directory creation and conflict handling
- `ln_s(to, from)` - Low-level symlink creation with directory setup

### Package Structure
- `packages/essential/` - Shell and terminal configuration
- `packages/nvim/` - Neovim with Lua configuration and plugins
- `packages/git/` - Git configuration
- `packages/ghostty/` - Ghostty terminal configuration
- `packages/wezterm/` - WezTerm configuration

### Neovim Configuration
- Entry point: `packages/nvim/init.lua`
- Main configuration: `packages/nvim/lua/ericst/`
- Plugin management via lazy.nvim
- Plugins organized in `packages/nvim/lua/ericst/plugins/`
- Custom snippets in `packages/nvim/snippets/`

## Development Notes

- The system uses Ruby's `FileUtils` for file operations
- Symlinks are created with full path resolution
- Existing files are protected unless `--force` is used
- Each package's install.rb uses the global `link` function provided by dotfiles.rb
- Do not add claude attribution in git commit messages. The CLAUDE.md file at the base of the project is enough.
