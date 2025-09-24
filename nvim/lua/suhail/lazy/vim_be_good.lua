-- lua/suhail/lazy/vim_be_good.lua
return {
  -- The mini-game (only loads when you run :VimBeGood)
  { "ThePrimeagen/vim-be-good", cmd = "VimBeGood" },

  -- Hardtime: opt-in; we enable/disable from suhail.practice commands
  {
    "m4xshen/hardtime.nvim",
    dependencies = { "MunifTanjim/nui.nvim" },
    opts = {
      enabled = false,  -- start OFF
      disabled_filetypes = { "qf", "help", "lazy", "TelescopePrompt" },
    },
    cmd = { "Hardtime" },  -- lazy-loads on our Practice* commands
  },
}
