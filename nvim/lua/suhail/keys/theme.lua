-- lua/suhail/keys/theme.lua
local map = vim.keymap.set

local function open_picker()
  local ok, iris = pcall(require, "iris")
  if not ok then return vim.notify("Iris not available", vim.log.levels.WARN) end
  iris.pick()
end

vim.api.nvim_create_user_command("ThemePick", open_picker, {})   -- keep your old command name
vim.api.nvim_create_user_command("ThemeToggle", function()
  local ok, iris = pcall(require, "iris"); if ok then iris.toggle() end
end, {})
vim.api.nvim_create_user_command("ThemeUse", function(a)
  local ok, iris = pcall(require, "iris"); if ok then iris.use(a.args) end
end, { nargs = 1, complete = function() return require("iris").list() end })

map("n", "<leader>ts", open_picker, { desc = "Theme: search & switch" })
