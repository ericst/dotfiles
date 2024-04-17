-- Configuring Telescope

return {
  {
    'nvim-telescope/telescope.nvim', branch = '0.1.x',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function ()
          -- Configuring Telescope
          local builtin = require('telescope.builtin')
          vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = "Fuzzy Find files" })
          vim.keymap.set('n', '<leader>fg', builtin.live_grep,  { desc = "Fuzzy grep" })
          vim.keymap.set('n', '<leader>fb', builtin.buffers,    { desc = "Fuzzy find buffer" })
          vim.keymap.set('n', '<leader>fh', builtin.help_tags,  { desc = "Fuzzy Find help tag" })
          vim.keymap.set('n', '<leader>fc', builtin.current_buffer_fuzzy_find, { desc = "Fuzzy find in current buffer" })
          vim.keymap.set('n', '<leader>fr', builtin.registers,  { desc = "Fuzzy find in registers" })
          vim.keymap.set('n', '<leader>fj', builtin.jumplist,   { desc = "Fuzzy find in jumplist" })
          vim.keymap.set('n', '<leader>fq', builtin.quickfix,   { desc = "Fuzzy find in quickfix" })
          vim.keymap.set('n', '<leader>fm', builtin.man_pages,  { desc = "Fuzzy find man pages" })
    end
  },
}
