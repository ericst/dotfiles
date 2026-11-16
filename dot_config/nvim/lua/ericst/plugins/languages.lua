-- Diverse language plugins
-- TODO: Check if those are needed of if they are integrated to vim now.
return {
   {'jubnzv/IEC.vim'},     -- IEC language support
   { 
      'kaarmu/typst.vim',  -- Typst
      ft = 'typst',
      lazy=false, 
   },
   { 
      "ziglang/zig.vim",   -- Zig support
      ft = { "zig" },
      config = function()
	 vim.g.zig_fmt_autosave = 1
      end 
   },
   {
      "stevearc/conform.nvim",  -- Formatter
      opts = {
         formatters_by_ft = {
            python = { "ruff_format" },
         },
         format_on_save = {
            timeout_ms = 500,
            lsp_fallback = true,
         },
      },
   },
}
