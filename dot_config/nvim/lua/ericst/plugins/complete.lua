-- This file contains configuration for completion.
-- This include the autocomplete and snippet engines as both are form of completion.

function fname()
  --code
end

return {
  {
    'hrsh7th/cmp-nvim-lsp',
    'hrsh7th/cmp-nvim-lua',
    'hrsh7th/cmp-buffer',
    'hrsh7th/cmp-path',
    { 'saadparwaiz1/cmp_luasnip', dependencies =  {{ 'L3MON4D3/LuaSnip', 
                                                      version = "v2.*" ,
                                                      build = "make install_jsregexp"
                                                    }}
    },
    { 'hrsh7th/nvim-cmp',
      config = function ()
        vim.opt.completeopt = {'menu', 'menuone', 'noselect'}

        local cmp = require('cmp')
        local ls = require('luasnip')



        local select_opts = {behavior = cmp.SelectBehavior.Select}
        -- Configure nvim-cmp and LuaSnip keybindings
        cmp.setup({
          snippet = {
            expand = function(args)
              ls.lsp_expand(args.body)
            end
          },

          window = {
            documentation = cmp.config.window.bordered()
          },

          mapping = cmp.mapping.preset.insert({
            ['<C-p>'] = cmp.mapping(function (fallback)
                if cmp.visible() then
                  cmp.select_prev_item(select_opts)
                elseif  ls.choice_active() then
                  ls.change_choice(-1)
                end
              end, {'i', 's'}),
            ['<C-n>'] = cmp.mapping(function (fallback)
                  if cmp.visible() then
                    cmp.select_next_item(select_opts)
                  elseif  ls.choice_active() then
                    ls.change_choice(1)
                  end
                end, {'i', 's'}),
            ['<C-u>'] = cmp.mapping.scroll_docs(-4),
            ['<C-d>'] = cmp.mapping.scroll_docs(4),

            ['<C-e>'] = cmp.mapping.abort(),

            ['<C-l>'] = cmp.mapping(function(fallback)
              if ls.jumpable(1) then
                ls.jump(1)
              end
            end, {'i', 's'}),

            ['<C-h>'] = cmp.mapping(function(fallback)
              if ls.jumpable(-1) then
                ls.jump(-1)
              end
            end, {'i', 's'}),

            ['<CR>'] = cmp.mapping(function(fallback)
              if cmp.get_selected_entry() ~= nil then
                  cmp.confirm({ select = false, })
              else
                  fallback()
              end
            end, {'i', 's'}),

            ['<C-k>'] = cmp.mapping(function(fallback)
              if cmp.visible() then
                      cmp.confirm({ select = true, })
              else
                if ls.expandable() then
                  ls.expand()
                else
                  fallback() -- TODO: Find a way to use Telescope for Unicode characters
                end 
              end
            end, {'i', 's'}),


          }),

          sources = cmp.config.sources({
            {name = 'path'},
            {name = 'nvim_lua'},
            {name = 'nvim_lsp'},
            {name = 'luasnip', keyword_length = 2},
            {name = 'buffer', keyword_length = 4},
          }),
        })


      -- Loading the snippets
      local load_from_lua = require("luasnip.loaders.from_lua").load
      local load_paths = { paths = vim.fn.stdpath("config") .. "/snippets" }

      load_from_lua(load_paths)
      vim.keymap.set('n', '<leader>cs', function ()
        load_from_lua(load_paths)
      end, { desc = "Force reload snippets" })
    end}
 }
}
