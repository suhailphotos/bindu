return {
  {
    -- use local path while the repo is private; switch to "suhailphotos/iris" later
    dir = vim.fn.expand("~/Library/CloudStorage/Dropbox/matrix/iris"),
    name = "iris",
    lazy = false,         -- apply theme at startup
    priority = 1000,      -- win the colorscheme race
    dependencies = {
      { "nvim-telescope/telescope.nvim", optional = true },
      { "suhailphotos/mira",  name = "mira" },
      { "nordtheme/vim",      name = "nord" },
      { "rose-pine/neovim",   name = "rose-pine" },
    },
    opts = {
      default = vim.g.theme_default or vim.env.NVIM_THEME or "mira",
      -- families = { ... } -- optional: add/override families here
    },
  },
}
