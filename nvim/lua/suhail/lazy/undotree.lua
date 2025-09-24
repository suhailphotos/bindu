-- lua/suhail/lazy/undotree.lua
return {
  "mbbill/undotree",
  cmd = { "UndotreeToggle" },                 -- lazy-load on command
  keys = { { "<leader>u", "<cmd>UndotreeToggle<CR>", desc = "Undo tree" } },
}
