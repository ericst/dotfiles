-- Working with specialized buffers / files


-- From my stint with emacs, I liked the *scratch* buffer. This creates one on the fly and switches to it.
local function switch_to_scratch_buffer()
  if vim.fn.bufexists("*scratch*") == 0 then
    local ese_scratch_buf = vim.api.nvim_create_buf(true, true) -- The buffer is listed, but it is a temporary buffer
    vim.api.nvim_buf_set_name(ese_scratch_buf, "*scratch*")
    vim.api.nvim_set_option_value("filetype", "lua", { buf = ese_scratch_buf })
    vim.api.nvim_set_option_value("buftype", "nofile", { buf = ese_scratch_buf })
  end
  vim.cmd("buffer *scratch*") 
end

-- Helper function to edit a specific file
local function edit_file(filepath)
  vim.cmd("edit " .. filepath)
end


-- Let's set the keybindings
vim.keymap.set("n", "<leader>0", switch_to_scratch_buffer, { desc = "Open the *scratch* buffer" })
vim.keymap.set("n", "<leader>9", function() edit_file("~/journal.md") end , { desc = "Open global journal" })
