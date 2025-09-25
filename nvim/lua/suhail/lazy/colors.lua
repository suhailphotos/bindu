-- --------------------------------------------------
-- Theme plugins
-- --------------------------------------------------
return {
  -- Mira (ANSI-first mapping)
  {
    "suhailphotos/mira",
    name = "mira",
    branch = "main",
    lazy = false,      -- keep on rtp so :colorscheme mira works immediately
    priority = 1000,   -- win the race if something else sets a colorscheme
  },

  -- Nord (truecolor)
  {
    "nordtheme/vim",
    name = "nord",
    lazy = false,       -- only loads when we :colorscheme nord
  },

  { "rose-pine/neovim",
    name = "rose-pine",
    lazy = false
  },

  -- add catppuccin/tokyonight later if you want
}
