-- These are configuration for my LSP servers

vim.lsp.config("zls", {
    cmd = { "zls" },
    root_markers = { "build.zig", "build.zig.zon", ".git" },
    filetypes = { "zig" },
})

vim.lsp.enable("zls")
