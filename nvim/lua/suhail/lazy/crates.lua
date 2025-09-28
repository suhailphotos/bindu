-- crates.nvim (Cargo.toml niceties) + cmp source only in TOML buffers
return {
  "saecki/crates.nvim",
  ft = { "toml" },
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    require("crates").setup({
      completion = { cmp = { enabled = true } },
    })
    -- Add cmp source just for this buffer
    local ok, cmp = pcall(require, "cmp")
    if ok then
      cmp.setup.buffer({ sources = { { name = "crates" } } })
    end
  end,
}
