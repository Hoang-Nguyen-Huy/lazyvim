-- Setup our JDTLS server any time we open up a java file
vim.cmd([[
    augroup jdtls_lsp
        autocmd!
        autocmd FileType java lua require'config.jdtls'.setup_jdtls()
    augroup end
]])

-- The event data property will contain a string with either "default" or "light" respectively
vim.api.nvim_create_autocmd("User", {
  pattern = "CyberdreamToggleMode",
  callback = function(event)
    -- Your custom code here!
    -- For example, notify the user that the colorscheme has been toggled
    print("Switched to " .. event.data .. " mode!")
  end,
})
