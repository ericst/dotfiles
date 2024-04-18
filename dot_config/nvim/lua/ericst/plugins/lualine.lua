-- A little more information in the modeline
return {
  {'nvim-lualine/lualine.nvim', 
    opts = { options={
        theme = 'solarized',
        icons_enabled = false,
        component_separators = { left = '|', right = '|'},
        section_separators = { left = '', right = ''},
      }}
  }
}
