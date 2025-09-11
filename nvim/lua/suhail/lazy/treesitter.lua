return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  opts = {
    ensure_installed = {
      "vimdoc", "lua", "bash", "javascript", "typescript", "python", "c", "rust",
      "markdown", "markdown_inline",
    },
    sync_install = false,
    auto_install = true,
    indent = { enable = true },
    -- You kept regex for markdown; fine to keep. Adjust later if you prefer pure TS.
    highlight = { enable = true, additional_vim_regex_highlighting = { "markdown" } },
  },
  config = function(_, opts)
    require("nvim-treesitter.configs").setup(opts)
  end,
}
