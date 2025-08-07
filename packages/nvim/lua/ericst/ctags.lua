
vim.cmd [[set tags="./tags,tags" ]] -- TODO: Somehow it doesn't work...


-- function to call ctags in the background to update the ctags file
function ese_generate_tags()
  print("Launching 'ctags -R .' in the background")
  vim.system({"ctags", "-R", "."}, { text = true }, function ()
    print("Background ctags finished")
  end)
end

-- Create a user command for calling that function
vim.api.nvim_create_user_command("CtagsGenerate", ese_generate_tags, { desc="Generates ctags"})


-- Automatically create tags files on save for some files
vim.api.nvim_create_autocmd({"BufWritePost"}, {
  pattern = {"*.c", "*.cpp", "*.zig", "*.py", ".lua"}, 
  callback = ese_generate_tags
})
