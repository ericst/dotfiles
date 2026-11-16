-- These are configuration for my LSP servers

vim.lsp.config("zls", {
    cmd = { "zls" },
    root_markers = { "build.zig", "build.zig.zon", ".git" },
    filetypes = { "zig" },
})

vim.lsp.enable("zls")

vim.lsp.config("basedpyright", {
    cmd = { "basedpyright-langserver", "--stdio" },
    root_markers = { "pyproject.toml", "setup.py", "setup.cfg", ".git" },
    filetypes = { "python" },
    settings = {
        basedpyright = {
            analysis = {
                autoSearchPaths = true,
                useLibraryCodeForTypes = true,
            },
        },
    },
})

vim.lsp.enable("basedpyright")
