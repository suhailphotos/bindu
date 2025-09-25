return {
  {
    "suhailphotos/iris",
    name = "iris",
    lazy = false,         -- apply theme at startup
    priority = 1000,      -- win the colorscheme race
    dependencies = {
      { "nvim-telescope/telescope.nvim", optional = true },
      { "suhailphotos/mira",  name = "mira" },
      { "nordtheme/vim",      name = "nord" },
      { "rose-pine/neovim",   name = "rose-pine" },
      { "catppuccin/nvim",     name = "catppuccin" },
      { "folke/tokyonight.nvim", name = "tokyonight" },
    },
    opts = {
      default = vim.g.theme_default or vim.env.NVIM_THEME or "mira",
      -- families = { ... } -- optional: add/override families here
    },
  },
}
