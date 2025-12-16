-- Please don't forget to that this filetype is also part of the ctags updates

-- Use ZIG_STD_DIR environment variable if available, fallback to hardcoded path
local zig_std_tags = os.getenv("ZIG_STD_DIR") and (os.getenv("ZIG_STD_DIR") .. "/tags") or "~/Projects/zig/lib/std/tags"
vim.cmd(string.format([[ setlocal tags+=tags,%s ]], zig_std_tags)) -- Somehow vim.opt_local doesntwork...
