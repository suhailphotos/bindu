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
    lazy = true,
    opts = { disable_background = true },
  },

  -- ─────────────────────────────────────────────────────────────────────────────
  -- Catppuccin: two *commands* that apply your palettes
  --   :CatFrappe  -> your Frappe palette
  --   :CatMocha   -> Mocha variant using your Xcode DarkHC palette
  -- Everything not specified in color_overrides falls back to Catppuccin defaults.
  -- ─────────────────────────────────────────────────────────────────────────────
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1000,
    opts = {
      flavour = "mocha",                 -- default boot flavor (command will switch)
      transparent_background = true,     -- show your bg
      term_colors = true,

      color_overrides = {
        -- Your terminal.sexy Frappe mapping → Catppuccin keys
        frappe = {
          crust  = "#1e1e27",
          mantle = "#2c2f40",
          base   = "#24273a",  -- keep mid bg close to upstream
          text   = "#d1d8f6",

          red      = "#e88295",
          maroon   = "#f26681",  -- bright red
          green    = "#8ad1bb",
          yellow   = "#f4c99a",
          peach    = "#f4a88d",  -- warm accent
          blue     = "#7eabf3",
          sky      = "#7daaee",  -- bright blue
          sapphire = "#a2e8e5",  -- bright cyan
          pink     = "#f4b8e4",
          mauve    = "#efa7dc",  -- bright magenta
          lavender = "#c2cef8",  -- bright white-ish
          teal     = "#a8e7dd",
        },

        -- Mocha painted with your Xcode DarkHC palette
        mocha = {
          crust  = "#15151f",
          mantle = "#2a2b3f",
          -- base not forced: let Mocha’s defaults fill in
          text   = "#cfd6f5",

          red      = "#f38ba8",
          maroon   = "#da8796",  -- (your bright red same as red; fine)
          green    = "#a1d9e6",  -- your palette's “green” leans cyan; intentional
          yellow   = "#e6cba5",
          peach    = "#e9ab92",  -- bright-yellow-ish accent
          blue     = "#85a5e8",
          sky      = "#87abf5",  -- bright blue
          sapphire = "#73bade",  -- bright cyan
          pink     = "#f4a5dc",
          mauve    = "#e176bf",  -- bright magenta
          lavender = "#c5cff5",  -- bright white
          teal     = "#97cde8",  -- ANSI cyan
        },
      },

      integrations = {
        treesitter = true, cmp = true, telescope = true, gitsigns = true, lsp_trouble = true,
      },

      -- Keep your small UI touches
      custom_highlights = function(C)
        return {
          StatusLine   = { fg = "#848faa", bg = "#262938", bold = false },
          StatusLineNC = { fg = C.surface2, bg = "NONE" },
          MsgArea      = { fg = "#848faa", bg = "NONE" },
          MsgSeparator = { fg = C.surface1, bg = "NONE" },
          ModeMsg      = { fg = C.green,    bg = "NONE", bold = true },
          MoreMsg      = { fg = C.lavender, bg = "NONE" },
          WarningMsg   = { fg = C.peach,    bg = "NONE" },
          ErrorMsg     = { fg = C.red,      bg = "NONE" },
          WinSeparator = { fg = C.surface1, bg = "NONE" },
        }
      end,
    },
    config = function(_, opts)
      require("catppuccin").setup(opts)

      -- palettes for terminal + window bg/fg (16 + 2)
      local FRAPPE_TERM = {
        "#2c2f40", "#e88295", "#8ad1bb", "#f4c99a",
        "#7eabf3", "#f4b8e4", "#a8e7dd", "#848faa",
        "#535a73", "#f26681", "#65c7a8", "#f4a88d",
        "#7daaee", "#efa7dc", "#a2e8e5", "#c2cef8",
      }
      local FRAPPE_FG, FRAPPE_BG = "#d1d8f6", "#1e1e27"

      local MOCHA_TERM = {
        "#2a2b3f", "#da8796", "#b5dde6", "#e6cba5",
        "#8da9e3", "#f4a5dc", "#97cde8", "#7c87a8",
        "#4c4e69", "#da8796", "#9ad9e6", "#e9ab92",
        "#87abf5", "#e176bf", "#73bade", "#c5cff5",
      }
      local MOCHA_FG, MOCHA_BG = "#cfd6f5", "#191821"

      local function apply_term_and_bg(term16, fg, bg)
        for i = 0, 15 do vim.g["terminal_color_" .. i] = term16[i + 1] end
        vim.g.terminal_color_foreground = fg
        vim.g.terminal_color_background = bg
        local winbg = (vim.env.NVIM_TRANSPARENT == "1") and "NONE" or bg
        vim.api.nvim_set_hl(0, "Normal",      { fg = fg, bg = winbg })
        vim.api.nvim_set_hl(0, "NormalFloat", { fg = fg, bg = "NONE" })
      end

      -- Default boot (Mocha)
      vim.cmd.colorscheme("catppuccin-mocha")
      apply_term_and_bg(MOCHA_TERM, MOCHA_FG, MOCHA_BG)

      -- Commands
      vim.api.nvim_create_user_command("CatFrappe", function()
        vim.cmd.colorscheme("catppuccin-frappe")
        apply_term_and_bg(FRAPPE_TERM, FRAPPE_FG, FRAPPE_BG)
      end, {})

      vim.api.nvim_create_user_command("CatMocha", function()
        vim.cmd.colorscheme("catppuccin-mocha")
        apply_term_and_bg(MOCHA_TERM, MOCHA_FG, MOCHA_BG)
      end, {})

      -- Keep terminal/bg in sync if you switch via :colorscheme
      vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("SuhailCatppuccinPalettes", { clear = true }),
        callback = function()
          if not (vim.g.colors_name or ""):match("^catppuccin") then return end
          local flav = (vim.g.catppuccin_flavour or ""):lower()
          if flav == "mocha" then
            apply_term_and_bg(MOCHA_TERM, MOCHA_FG, MOCHA_BG)
          else
            apply_term_and_bg(FRAPPE_TERM, FRAPPE_FG, FRAPPE_BG)
          end
        end,
      })
    end,
  },

  -- ─────────────────────────────────────────────────────────────────────────────
  -- Xcode theme: keep *authentic* — no recolor, just easy variant commands.
  -- ─────────────────────────────────────────────────────────────────────────────
  {
    "arzg/vim-colors-xcode",
    name = "xcode",
    lazy = false,
    priority = 900,
    config = function()
      local xopts = {
        green_comments     = 0,
        dim_punctuation    = 1,
        emph_types         = 1,
        emph_funcs         = 0,
        emph_idents        = 0,
        match_paren_style  = 0,
      }

      local function set_xcode_options()
        for _, v in ipairs({ "dark", "darkhc", "light", "lighthc", "wwdc" }) do
          for k, val in pairs(xopts) do
            vim.g["xcode" .. v .. "_" .. k] = val
          end
        end
      end

      local function use_xcode(variant)
        set_xcode_options()
        local map = {
          auto    = "xcode",
          dark    = "xcodedark",
          darkhc  = "xcodedarkhc",
          light   = "xcodelight",
          lighthc = "xcodelighthc",
          wwdc    = "xcodewwdc",
        }
        vim.cmd.colorscheme(map[variant] or "xcodedark")
      end

      vim.api.nvim_create_user_command("XcodeAuto",    function() use_xcode("auto")    end, {})
      vim.api.nvim_create_user_command("XcodeDark",    function() use_xcode("dark")    end, {})
      vim.api.nvim_create_user_command("XcodeDarkHC",  function() use_xcode("darkhc")  end, {})
      vim.api.nvim_create_user_command("XcodeLight",   function() use_xcode("light")   end, {})
      vim.api.nvim_create_user_command("XcodeLightHC", function() use_xcode("lighthc") end, {})
      vim.api.nvim_create_user_command("XcodeWWDC",    function() use_xcode("wwdc")    end, {})
    end,
  },
}
