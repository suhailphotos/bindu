-- lua/suhail/treesitter_enable.lua
local ok, configs = pcall(require, "nvim-treesitter.configs")
if not ok then return end

configs.setup({
  -- IMPORTANT: don’t install at startup (avoids the tree-sitter CLI issues)
  ensure_installed = {},
  sync_install = false,
  auto_install = false,

  highlight = {
    enable = true,
    additional_vim_regex_highlighting = false, -- avoid double highlighting
  },

  indent = { enable = true },
})
