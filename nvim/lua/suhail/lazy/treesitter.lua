-- lua/suhail/lazy/treesitter.lua
return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  opts = {
    ensure_installed = {
      "vimdoc", "lua", "bash", "javascript", "typescript",
      "python", "c", "rust", "markdown", "markdown_inline",
    },
    sync_install = false,
    auto_install = true,
    highlight = { enable = true, additional_vim_regex_highlighting = { "markdown" } },
    indent = { enable = true },
  },
  config = function(_, opts)
    require("nvim-treesitter.configs").setup(opts)
  end,
}
