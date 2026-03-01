-- --------------------------------------------------
-- lua/suhail/lazy/treesitter.lua
-- --------------------------------------------------
return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  -- In the new version, we simply pass the table to 'opts'.
  -- lazy.nvim will handle the initialization for us.
  opts = {
    ensure_installed = {
      -- core
      "vimdoc", "vim", "lua", "bash",
      -- web
      "javascript", "typescript", "json", "yaml", "toml",
      -- langs I use
      "python", "rust", "c",
      -- docs
      "markdown", "markdown_inline",
      -- misc
      "dockerfile", "gitignore", "tmux",
    },
    sync_install = false,
    auto_install = false,
    highlight = {
      enable = true,
      additional_vim_regex_highlighting = { "markdown" }
    },
    indent = { enable = true },
  },
  -- The 'config' function is removed because require("nvim-treesitter.configs")
  -- no longer exists in the latest version of the plugin.
}
