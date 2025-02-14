return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  init = function()
    vim.o.timeout = true
    vim.o.timeoutlen = 500
  end,

  config = function()
    local wk = require("which-key")
    wk.setup({})

    wk.add({
      { "<leader>c", group = "Change" },
      { "<leader>f", group = "Fuzzy find" },
      { "<leader>w", group = "Workspace/Window" },
    })
  end
}
