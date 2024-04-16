-- Tmux integration

return {
  { 'aserowy/tmux.nvim',
    config = function ()
          local tmux = require("tmux")
          tmux.setup()
    end }
}-- tmux integration
