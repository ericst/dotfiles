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
   }
}
