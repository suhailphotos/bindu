-- lua/suhail/lazy/treesitter.lua
return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  opts = {
    ensure_installed = {
      -- core
      "vimdoc", "vim", "lua", "bash",
      -- web
      "javascript", "typescript", "json", "yaml", "toml",
      -- langs you asked for
      "python", "rust", "c",
      -- docs
      "markdown", "markdown_inline",
      -- misc
      "dockerfile", "gitignore", "tmux",
    },
    sync_install = false,
    auto_install = true,  -- set false if you don’t want auto-download on servers
    highlight = { enable = true, additional_vim_regex_highlighting = { "markdown" } },
    indent = { enable = true },
  },
  config = function(_, opts)
    require("nvim-treesitter.configs").setup(opts)
  end,
}
