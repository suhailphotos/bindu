-- lua/suhail/keys/theme.lua
local map = vim.keymap.set

local function open_picker()
  local ok, picker = pcall(require, "suhail.theme_picker")
  if not ok then
    return vim.notify("Theme picker unavailable", vim.log.levels.WARN)
  end
  picker.open()
end

vim.api.nvim_create_user_command("ThemePick", open_picker, {})
map("n", "<leader>ts", open_picker, { desc = "Theme: search & switch" })
