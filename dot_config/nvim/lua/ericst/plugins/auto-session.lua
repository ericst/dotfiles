return {
    { 'rmagatti/auto-session',
      dependencies = {'nvim-telescope/telescope.nvim'},
      config = function()
        require("auto-session").setup {
          log_level = "error",
          auto_session_suppress_dirs = { "~/", "~/Projects", "~/Downloads", "/", "/etc"},
          session_lens = {
            buftypes_to_ignore = {}, -- list of buffer types what should not be deleted from current session
            load_on_setup = true,
            theme_conf = { border = true },
            previewer = false,
          },
        }

        vim.keymap.set('n', '<leader>ws', "<cmd>SessionSave<CR>", { desc = "Save Session" })
        vim.keymap.set('n', '<leader>wr', "<cmd>SessionRestore<CR>", { desc = "Restore Session" })
        vim.keymap.set('n', '<leader>wf', require("auto-session.session-lens").search_session, { desc = "Fuzzy Find Session" })
      end
  },
}
