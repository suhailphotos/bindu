-- --------------------------------------------------
-- lua/suhail/lazy/treesitter.lua
-- --------------------------------------------------
return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
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
    auto_install = false,  -- <— no background downloads. Turn on if you want auto download
    highlight = { enable = true, additional_vim_regex_highlighting = { "markdown" } },
    indent = { enable = true },
  },
  config = function(_, opts)
    require("nvim-treesitter.configs").setup(opts)
  end,
}
