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

    wk.register({
      ["<leader>"] = {
        c = { name = "+Change" },
        f = { name = "+Fuzzy find" },
        h = { name = "+Harpoon" },
        w = { name = "+Workspace" },
      }
    })
  end
}
