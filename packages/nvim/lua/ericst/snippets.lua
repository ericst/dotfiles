-- Taken from https://boltless.me/posts/neovim-config-without-plugins-2025/


---@param trigger string trigger string for snippet
---@param body string snippet text that will be expanded or lua function that will be executed
---@param opts? vim.keymap.set.Opts
---
---Refer to <https://microsoft.github.io/language-server-protocol/specification/#snippet_syntax>
---for the specification of valid body.
function vim.snippet.add(trigger, body, opts)
    vim.keymap.set("ia", trigger, function()
        -- If abbrev is expanded with keys like "(", ")", "<cr>", "<space>",
        -- don't expand the snippet. Only accept "<c-]>" as a trigger key.
        local c = vim.fn.nr2char(vim.fn.getchar(0))
        if c ~= "" then
            vim.api.nvim_feedkeys(trigger .. c, "i", true)
            return
        end
        if type(body) == "function" then
          body()
        else
          vim.snippet.expand(body)
        end
    end, opts)
end

-- Date functions
local function date(format)
    vim.api.nvim_feedkeys(vim.fn.trim(vim.fn.system("date +'" .. format .. " '")), "i", true)
end

local function iso_date(precision)
    vim.api.nvim_feedkeys(vim.fn.trim(vim.fn.system("date -I'" .. precision .. "'")), "i", true)
end

vim.snippet.add("date", function () date("%+4Y-%m-%d") end, { buffer = false } )
vim.snippet.add("date-day", function () date("%+4Y-%m-%d %a") end, { buffer = false } )
vim.snippet.add("date-day-time", function () date("%+4Y-%m-%d %a %H:%M") end, { buffer = false } )
vim.snippet.add("date-time", function () date("%+4Y-%m-%d %H:%M") end, { buffer = false } )
vim.snippet.add("iso", function () date("%+4Y-%m-%d") end, { buffer = false } )
vim.snippet.add("iso-week", function () date("W%V") end, { buffer = false } )
vim.snippet.add("iso-date-week", function () date("%G-W%V") end, { buffer = false } )
vim.snippet.add("iso-date-minutes", function () is_date("minutes") end, { buffer = false } )
vim.snippet.add("iso-date-seconds", function () is_date("seconds") end, { buffer = false } )
