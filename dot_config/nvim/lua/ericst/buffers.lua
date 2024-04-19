-- Working with specialized buffers / files

-- From my stint with emacs, I liked the *scratch* buffer. This creates one on the fly and switches to it.
local function create_or_switch_scratch_buffer(bufname)
  if vim.fn.bufexists(bufname) == 0 then
    vim.cmd("new " .. bufname)
    local ese_scratch_buf =  vim.api.nvim_get_current_buf()

    vim.api.nvim_buf_set_option(ese_scratch_buf, "buftype", "nofile")   -- The buffer has now file associated to it
    vim.api.nvim_buf_set_option(ese_scratch_buf, "swapfile", false)     -- No swapping
  else
    vim.cmd("buffer " .. bufname) 
  end
end

-- BufLeave 
local function create_or_switch_autosave_buffer(filepath)
  if vim.fn.bufexists(filepath) == 0 then
    vim.cmd("edit " .. filepath)
    local buf =  vim.api.nvim_get_current_buf()

    vim.api.nvim_buf_set_option(buf, "bufhidden", "hide") -- Do not show the buffer
    vim.api.nvim_buf_set_option(buf, "buflisted", false) -- Do not allow to switch to it with bn.

    vim.api.nvim_create_autocmd( {"BufLeave"}, { 
      buffer = buf,
      command = "write"
    })
  else

    vim.cmd("buffer " .. filepath) 
  end
end

-- Helper function to edit a specific file
local function edit_file(filepath)
  vim.cmd("edit " .. filepath)
end

-- Let's set the keybindings
vim.keymap.set("n", "<leader>0", function() create_or_switch_scratch_buffer("*scratch*") end, { desc = "Open the *scratch* buffer" })
vim.keymap.set("n", "<leader>9", function() create_or_switch_autosave_buffer("~/journal.md") end , { desc = "Open global journal" })
