return {
  'echasnovski/mini.nvim', 
  version = '*',
  config = function()
    require('mini.ai').setup()            -- For extended text object with treesitter
    require('mini.pairs').setup()         -- For automatic pairs
    require('mini.surround').setup()      -- For surround
  end
}
