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
      flavour = "mocha",                 -- default boot flavor
      transparent_background = true,     -- your Cat* should be transparent by default
      term_colors = true,

      color_overrides = {
        frappe = {
          crust  = "#1e1e27",
          mantle = "#2c2f40",
          base   = "#24273a",
          text   = "#d1d8f6",
          red      = "#e88295",
          maroon   = "#f26681",
          green    = "#8ad1bb",
          yellow   = "#f4c99a",
          peach    = "#f4a88d",
          blue     = "#7eabf3",
          sky      = "#7daaee",
          sapphire = "#a2e8e5",
          pink     = "#f4b8e4",
          mauve    = "#efa7dc",
          lavender = "#c2cef8",
          teal     = "#a8e7dd",
        },
        mocha = {
          crust  = "#15151f",
          mantle = "#2a2b3f",
          text   = "#cfd6f5",
          red      = "#f38ba8",
          maroon   = "#da8796",
          green    = "#a1d9e6",
          yellow   = "#e6cba5",
          peach    = "#e9ab92",
          blue     = "#85a5e8",
          sky      = "#87abf5",
          sapphire = "#73bade",
          pink     = "#f4a5dc",
          mauve    = "#e176bf",
          lavender = "#c5cff5",
          teal     = "#97cde8",
        },
      },

      integrations = {
        treesitter = true, cmp = true, telescope = true, gitsigns = true, lsp_trouble = true,
      },

      custom_highlights = function(C)
        -- choose per-flavour so Mocha/Frappe get different greys if you want
        local flav = (vim.g.catppuccin_flavour or "mocha"):lower()
        local comment_fg = (flav == "mocha") and "#6b7093" or "#848faa"  -- Mocha | Frappe

        return {
          -- comments
          Comment        = { fg = comment_fg, italic = false },   -- regex highlighting
          ["@comment"]   = { fg = comment_fg, italic = false },   -- Treesitter

          -- (optional) special comment kinds
          ["@comment.todo"]     = { fg = C.peach,    bold = true },
          ["@comment.note"]     = { fg = C.lavender, italic = true },
          ["@comment.warning"]  = { fg = C.yellow,   bold = true },
          ["@comment.error"]    = { fg = C.red,      bold = true },

          -- your existing UI overrides …
          StatusLine   = { fg = "#848faa", bg = "#1e1f2f", bold = false },
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
      -- Respect external override at boot: NVIM_TRANSPARENT=0 -> force opaque Catppuccin
      if vim.env.NVIM_TRANSPARENT == "0" then
        opts.transparent_background = false
      end

      require("catppuccin").setup(opts)

      -- 16-color palettes (terminal only; we don’t touch window bg here)
      local FRAPPE_TERM = {
        "#2c2f40", "#e88295", "#8ad1bb", "#f4c99a",
        "#7eabf3", "#f4b8e4", "#a8e7dd", "#848faa",
        "#535a73", "#f26681", "#65c7a8", "#f4a88d",
        "#7daaee", "#efa7dc", "#a2e8e5", "#c2cef8",
      }
      local MOCHA_TERM = {
        "#2a2b3f", "#da8796", "#b5dde6", "#e6cba5",
        "#8da9e3", "#f4a5dc", "#97cde8", "#7c87a8",
        "#4c4e69", "#da8796", "#9ad9e6", "#e9ab92",
        "#87abf5", "#e176bf", "#73bade", "#c5cff5",
      }

      local function apply_term_colors(term16)
        for i = 0, 15 do vim.g["terminal_color_" .. i] = term16[i + 1] end
      end

      -- Default boot (Mocha w/ your Xcode-ish palette)
      vim.cmd.colorscheme("catppuccin-mocha")
      apply_term_colors(MOCHA_TERM)

      -- Your explicit commands
      vim.api.nvim_create_user_command("CatFrappe", function()
        vim.cmd.colorscheme("catppuccin-frappe")
        apply_term_colors(FRAPPE_TERM)
      end, {})

      vim.api.nvim_create_user_command("CatMocha", function()
        vim.cmd.colorscheme("catppuccin-mocha")
        apply_term_colors(MOCHA_TERM)
      end, {})

      -- Re-apply terminal palette if you switch Catppuccin flavor via :colorscheme
      vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("SuhailCatTerm", { clear = true }),
        callback = function()
          if not (vim.g.colors_name or ""):match("^catppuccin") then return end
          local flav = (vim.g.catppuccin_flavour or ""):lower()
          apply_term_colors(flav == "mocha" and MOCHA_TERM or FRAPPE_TERM)
        end,
      })

      -- Simple transparency toggles that only affect Catppuccin (and reapply if active)
      local function reapply_if_catppuccin()
        if (vim.g.colors_name or ""):match("^catppuccin") then
          require("catppuccin").setup(opts)
          vim.cmd("colorscheme " .. vim.g.colors_name)
        end
      end

      vim.api.nvim_create_user_command("TransparentOn", function()
        vim.env.NVIM_TRANSPARENT = "1"
        opts.transparent_background = true
        reapply_if_catppuccin()
      end, {})

      vim.api.nvim_create_user_command("TransparentOff", function()
        vim.env.NVIM_TRANSPARENT = "0"
        opts.transparent_background = false
        reapply_if_catppuccin()
      end, {})

      vim.api.nvim_create_user_command("TransparentToggle", function()
        local on = (vim.env.NVIM_TRANSPARENT ~= "0")
        vim.env.NVIM_TRANSPARENT = on and "0" or "1"
        opts.transparent_background = not on
        reapply_if_catppuccin()
      end, {})
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
