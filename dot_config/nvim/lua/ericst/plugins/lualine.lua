-- A little more information in the modeline
return {
  {'nvim-lualine/lualine.nvim', 
    opts = { options={
        icons_enabled = false,
        component_separators = { left = '|', right = '|'},
        section_separators = { left = '', right = ''},
      }}
  }
}
