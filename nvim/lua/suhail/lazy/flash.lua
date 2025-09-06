-- lua/suhail/lazy/flash.lua
return {
  "folke/flash.nvim",
  event = "VeryLazy",
  opts = {
    -- sensible defaults; tweak later if you want
    labels = "asdfghjkl;qwertyuiopzxcvbnm",
    modes = {
      search = { enabled = true },     -- enhances / and ?
      char   = { enabled = false },    -- leave f/F/t/T alone for now
    },
  },
  -- stylua: ignore
  keys = {
    -- YouTuber-style mappings (kept as requested)
    { "zk",     mode = { "n", "x", "o" }, function() require("flash").jump() end,              desc = "Flash jump" },
    { "Zk",     mode = { "n", "x", "o" }, function() require("flash").treesitter() end,        desc = "Flash TS" },
    { "r",      mode = "o",               function() require("flash").remote() end,            desc = "Flash remote" },
    { "R",      mode = { "o", "x" },      function() require("flash").treesitter_search() end, desc = "Flash TS search" },
    -- Heads up: <C-s> can pause some terminals; it’s only in cmdline here.
    { "<C-s>",  mode = { "c" },           function() require("flash").toggle() end,            desc = "Flash toggle (/ ?)" },
  },
}
