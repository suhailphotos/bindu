-- lua/suhail/lazy/fugitive.lua
return {
  "tpope/vim-fugitive",
  cmd = { "Git", "Gwrite", "Gdiffsplit", "Gvdiffsplit", "Gread" },  -- common cmds
  keys = {
    { "<leader>gs", "<cmd>Git<CR>", desc = "Fugitive: status" },    -- safe, won’t clash
  },
}
