vim.keymap.set("n", "<leader>wh", ":split<cr>", { desc = "[W]indow Split [H]orizontal" })

-- Add a custom keybinding to toggle the colorscheme
vim.api.nvim_set_keymap("n", "<leader>tt", ":CyberdreamToggleMode<CR>", { noremap = true, silent = true })

-- Smart global transparency toggler
local transparent = true
vim.keymap.set("n", "<leader>uT", function()
  transparent = not transparent
  local current_theme = vim.g.colors_name
  if current_theme == "cyberdream" then
    require("cyberdream").setup({ transparent = transparent })
  elseif current_theme:find("tokyonight") then
    require("tokyonight").setup({ transparent = transparent })
  end
  vim.cmd("colorscheme " .. current_theme)
  print("Transparency: " .. (transparent and "Enabled" or "Disabled"))
end, { desc = "Toggle [u]ser [T]ransparency" })
