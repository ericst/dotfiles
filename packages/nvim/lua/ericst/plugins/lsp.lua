-- Configuration of LSP 


return {
  {'neovim/nvim-lspconfig',
    dependencies = {
      {'williamboman/mason.nvim'},
      {'williamboman/mason-lspconfig.nvim'},
      {'VonHeikemen/lsp-zero.nvim', branch = 'v3.x'},
      {'neovim/nvim-lspconfig'},
    },
    config = function ()
        -- Configuration of LSP Zero
        local lsp_zero = require('lsp-zero')

        lsp_zero.on_attach(function(client, bufnr)
          -- see :help lsp-zero-keybindings
          -- to learn the available actions
          lsp_zero.default_keymaps({buffer = bufnr})
        end)

        require('mason').setup({})
        require('mason-lspconfig').setup({
          ensure_installed = {},
          handlers = {
            lsp_zero.default_setup,
          },
        })
    end
  }
}
