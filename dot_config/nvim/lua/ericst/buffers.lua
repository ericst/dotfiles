-- Working with specialized buffers / files

-- From my stint with emacs, I liked the *scratch* buffer. This creates one on the fly and switches to it.
function ese_scratch()
  -- Use 'nofile' to prevent disk interaction/swaps 
  -- and use a fixed name so we don't create multiple "Untitled" buffers.
  local bufname = "_scratch_"
  local target_buf = vim.fn.bufnr(bufname)

  if target_buf == -1 then
    vim.cmd("new " .. bufname)
    local buf = vim.api.nvim_get_current_buf()
    
    -- Specialized scratch settings
    vim.api.nvim_set_option_value("buftype", "nofile", { buf = buf })
    vim.api.nvim_set_option_value("swapfile", false,   { buf = buf })
  else
    vim.api.nvim_set_current_buf(target_buf)
  end
end

--- Executes a command and captures its output in a reusable named buffer.
-- @param cmd string|nil The command to run. If provided, it pre-fills the prompt.
-- @param bufname string The name of the buffer that receives the output.
function ese_command(cmd, bufname)
  local initial_text = cmd or ""

  vim.ui.input({ prompt = 'Command: ', default = initial_text }, function(input)
    if not input or input == "" then
      return
    end

    local buf = vim.fn.bufnr(bufname)
    if buf == -1 then
      vim.cmd("enew")
      buf = vim.api.nvim_get_current_buf()
      vim.api.nvim_buf_set_name(buf, bufname)
    else
      vim.api.nvim_set_current_buf(buf)
    end

    -- Keep editable command output in memory without swaps or write prompts.
    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].bufhidden = "hide"
    vim.bo[buf].swapfile = false
    vim.bo[buf].modifiable = true

    local result = vim.fn.systemlist(input)
    if #result > 0 then
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, result)
    else
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "[No output]" })
    end

    -- Generated output itself is not an unsaved edit; user changes still are.
    vim.bo[buf].modified = false
  end)
end

