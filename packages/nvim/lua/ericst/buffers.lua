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

--- Executes a command and captures output into an ephemeral vertical split.
-- @param cmd string|nil The command to run. If provided, will be used as pre-filled input.
function ese_command(cmd)
  local initial_text = cmd or ""
  
  vim.ui.input({ prompt = 'Command: ', default = initial_text }, function(input)
    if input and input ~= "" then
      -- 1. Create the vertical split/buffer
      vim.cmd("enew")
      local buf = vim.api.nvim_get_current_buf()

      -- 2. Set ephemeral properties (wipe on close, no swap, no file)
      vim.bo[buf].buftype   = "nofile"
      vim.bo[buf].bufhidden = "wipe"
      vim.bo[buf].swapfile  = false

      -- 3. Run command and populate lines
      local result = vim.fn.systemlist(input)
      if #result > 0 then
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, result)
      else
          vim.api.nvim_buf_set_lines(buf, 0, -1, false, {"[No output]"})
      end
    end
  end)
end

