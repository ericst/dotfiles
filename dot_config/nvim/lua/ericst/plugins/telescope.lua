-- Configuring Telescope

return {
  {
    'nvim-telescope/telescope.nvim', branch = '0.1.x',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function ()
          -- Configuring Telescope
          local builtin = require('telescope.builtin')
          vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
          vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
          vim.keymap.set('n', '<leader>fb', builtin.buffers, {})
          vim.keymap.set('n', '<leader>fh', builtin.help_tags, {})
          vim.keymap.set('n', '<leader>fc', builtin.current_buffer_fuzzy_find, {})
          vim.keymap.set('n', '<leader>fr', builtin.registers, {})
          vim.keymap.set('n', '<leader>fj', builtin.jumplist, {})
          vim.keymap.set('n', '<leader>fq', builtin.quickfix, {})
          vim.keymap.set('n', '<leader>fm', builtin.man_pages, {})
    end
  },
}
