-- lua/suhail/lazy/colors.lua
local function ColorMyPencils(color)
  if vim.env.NVIM_TRANSPARENT == "1" then
    color = color or "rose-pine"
    vim.cmd.colorscheme(color)
    vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
    vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
  end
end

return {
  -- Optional alternatives, available on demand with :colorscheme X
  {
    "folke/tokyonight.nvim",
    name = "tokyonight",
    lazy = true,
    opts = {
      style = "storm",
      transparent = true,
      terminal_colors = true,
      styles = { comments = { italic = false }, keywords = { italic = false }, sidebars = "dark", floats = "dark" },
    },
  },

  {
    "rose-pine/neovim",
    name = "rose-pine",
    lazy = true,                     -- make it on-demand now
    opts = { disable_background = true },
  },

  -- 🔹 Your default theme at startup
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,                    -- start plugin (loads at startup)
    priority = 1000,                 -- load before other start plugins
    opts = {
      flavour = "frappe",             -- or "auto" to follow :set background
      transparent_background = true, -- you can drop your manual bg = "none"
      color_overrides = {
        frappe = {
          crust = "#1e1e27",
          mantle = "#2c2f40",
          base = "#24273a",
          green = "#8ad1bb",
          peach = "#f4a88d",
          yellow = "#f4c99a",
          teal = "#a8e7dd",
          blue = "#7eabf3",
          pink = "#f4b8e4",

        },
      },
      term_colors = true,
      integrations = {
        treesitter = true,
        cmp = true,
        telescope = true,
        gitsigns = true,
        lsp_trouble = true,
      },
    custom_highlights = function(C)
      return {
        -- statusline (active/inactive)
        StatusLine   = { fg = "#848faa", bg = "#262938", bold = false },
        StatusLineNC = { fg = C.surface2, bg = "NONE" },

        -- message/command area
        MsgArea      = { fg = "#848faa",     bg = "NONE" },
        MsgSeparator = { fg = C.surface1, bg = "NONE" },

        -- common message kinds
        ModeMsg      = { fg = C.green,     bg = "NONE", bold = true },
        MoreMsg      = { fg = "#c2cef8",    bg = "NONE", bold = false },
        WarningMsg   = { fg = C.peach,    bg = "NONE", bold = false },
        ErrorMsg     = { fg = C.red,      bg = "NONE", bold = false },

        -- optional: window split line
        WinSeparator = { fg = C.surface1, bg = "NONE" },
      }
      end,
    },
    config = function(_, opts)
      require("catppuccin").setup(opts)   -- lazy.nvim will call this automatically when you use `opts`, but explicit is fine
      vim.cmd.colorscheme("catppuccin")   -- or "catppuccin-mocha", "catppuccin-macchiato", etc.
    end,
  },
}
