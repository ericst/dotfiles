-- Tmux integration

return {
  { 'aserowy/tmux.nvim',
    config = function ()
          local tmux = require("tmux")
          tmux.setup({copy_sync = {
                                    sync_clipboard=false,},})
    end }
}-- tmux integration
