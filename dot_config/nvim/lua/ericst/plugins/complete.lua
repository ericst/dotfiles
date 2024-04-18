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
    { 'saadparwaiz1/cmp_luasnip', dependencies =  { { 'L3MON4D3/LuaSnip', version = "v2.*" } }},
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
                else
                  fallback()
                end
              end),
            ['<C-n>'] = cmp.mapping(function (fallback)
                  if cmp.visible() then
                    cmp.select_next_item(select_opts)
                  elseif  ls.choice_active() then
                    ls.change_choice(1)
                  else
                    fallback()
                  end
                end),
            ['<C-u>'] = cmp.mapping.scroll_docs(-4),
            ['<C-d>'] = cmp.mapping.scroll_docs(4),

            ['<C-e>'] = cmp.mapping.abort(),

            ['<C-f>'] = cmp.mapping(function(fallback)
              if ls.jumpable(1) then
                ls.jump(1)
              end
            end, {'i', 's'}),

            ['<C-b>'] = cmp.mapping(function(fallback)
              if ls.jumpable(-1) then
                ls.jump(-1)
              end
            end, {'i', 's'}),

            ['<CR>'] = cmp.mapping(function(fallback)
              if cmp.visible() then
                  if ls.expandable() then
                      ls.expand()
                  else
                      cmp.confirm({ select = true, })
                  end
              else
                  fallback()
              end
            end),


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
      local load_paths = { paths = "~/.config/nvim/lua/ericst/snippets" }

      load_from_lua(load_paths)
      vim.keymap.set('n', '<leader>cs', function ()
        load_from_lua(load_paths)
      end, { desc = "Force reload snippets" })
    end}
 }
}
