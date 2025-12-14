-- lua/suhail/lazy/crates.lua
return {
  "saecki/crates.nvim",
  event = { "BufReadPre Cargo.toml", "BufNewFile Cargo.toml" },
  dependencies = { "nvim-lua/plenary.nvim" },
  opts = {
    lsp = { enabled = true, actions = true, completion = true, hover = true },
    completion = { crates = { enabled = true, max_results = 8, min_chars = 3 } },
  },
  config = function(_, opts)
    require("crates").setup(opts)
  end,
}
