# ericst's dotfiles

A Python-based dotfiles management system that creates symlinks from configuration files in this repository to their expected locations in your home directory.

## Prerequisites

- Python 3 (any recent version)
- Unix-like system (Linux, macOS)
- Write permissions to your home directory

## Quick Start

```bash
# Install essential shell configuration
./dotfiles.py essential

# Install multiple packages
./dotfiles.py git nvim essential

# Force installation (overwrite existing files)
./dotfiles.py -f essential

# Get help
./dotfiles.py -h
```

## Available Packages

### `essential`
Core shell configuration including:
- **bashrc** - Enhanced bash configuration with better history, safety aliases, and navigation helpers
- **inputrc** - Readline configuration for improved command-line editing
- **bashrc.d/** - Modular bash configuration directory with toolbox support

### `git`
Git configuration:
- **gitconfig** - Global git settings and aliases

### `nvim`
Neovim configuration with Lua:
- **init.lua** - Main Neovim entry point
- **lua/ericst/** - Custom Lua configuration modules
- **snippets/** - Custom code snippets for various languages
- Includes plugin management via lazy.nvim

### `ghostty`
Ghostty terminal emulator configuration:
- **config** - Main Ghostty configuration
- **Desktop entries** - Application launchers for regular and workbox modes

### `wezterm`
WezTerm terminal emulator configuration:
- **wezterm.lua** - Complete WezTerm configuration

### `coding-agent`
AI coding assistant configuration:
- **CLAUDE.md** - Claude Code configuration and guidelines
- **AGENTS.md** - OpenCode agent configuration

## Usage Examples

### Basic Installation
```bash
# Install just the essentials
./dotfiles.py essential

# Add git configuration
./dotfiles.py git

# Set up complete development environment
./dotfiles.py essential git nvim
```

### Advanced Usage
```bash
# Force overwrite existing configurations
./dotfiles.py -f nvim

# Preview changes without executing
./dotfiles.py --dry-run essential

# Check what's installed
./dotfiles.py --status

# List available packages
./dotfiles.py --list

# Install with automatic yes to prompts
./dotfiles.py -f -y essential

# Install everything
./dotfiles.py essential git nvim ghostty wezterm coding-agent
```

## Command Line Options

- `-f, --force` - Force installation, overwriting existing files
- `-l, --list` - List available packages with descriptions
- `-s, --status` - Show installation status of all packages
- `-n, --dry-run` - Preview changes without executing them
- `-y, --yes` - Automatically answer yes to all prompts (for automation)
- `-h, --help` - Show help message

## How It Works

The system uses Python scripts to create symlinks from files in this repository to their target locations:

1. Each package is a directory under `packages/`
2. Each package contains an `install.toml` file that defines what to link using TOML format
3. The main `dotfiles.py` script processes packages and creates symlinks
4. Existing files are protected unless `--force` is used

### Link Functions

- `link(source, target)` - Create a single symlink
- `link_files_recursively(source_dir, target_dir)` - Recursively link all files in a directory

## Troubleshooting

### Permission Denied
```bash
# Make sure the script is executable
chmod +x dotfiles.py
```

### File Already Exists
```bash
# Use force mode to overwrite
./dotfiles.py -f package_name

# Or manually remove the conflicting file
rm ~/.bashrc
./dotfiles.py essential
```

### Package Not Found
```bash
# List available packages
./dotfiles.py --list

# Check installation status
./dotfiles.py --status

# Make sure you're in the dotfiles directory
cd /path/to/dotfiles
./dotfiles.py package_name
```

## Inspiration

This system was inspired by:
- [Manage your dotfiles like a boss](http://troydm.github.io/blog/2017/02/27/manage-your-dotfiles-like-a-boss/)
- [troydm/central](https://github.com/troydm/central)

The goal was to create a simple, local script without external gem dependencies.
