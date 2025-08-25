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

  -- Your default theme at startup
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1000,
    opts = {
      flavour = "frappe",
      transparent_background = false,   -- show your bg
      term_colors = true,

      -- Map your terminal.sexy hues onto Catppuccin names so UI uses them,
      -- anything not listed stays at Catppuccin defaults.
      color_overrides = {
        frappe = {
          -- backgrounds
          crust  = "#1e1e27",
          mantle = "#2c2f40",
          base   = "#24273a",
          text   = "#d1d8f6",

          -- your 16 mapped into sensible Catppuccin slots
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
        },
      },

      integrations = {
        treesitter = true, cmp = true, telescope = true, gitsigns = true, lsp_trouble = true,
      },

      -- keep any UI touches you want here (optional)
      custom_highlights = function(C)
        return {
          StatusLine   = { fg = "#848faa", bg = "#262938", bold = false },
          StatusLineNC = { fg = C.surface2, bg = "NONE" },
          MsgArea      = { fg = "#848faa", bg = "NONE" },
          MsgSeparator = { fg = C.surface1, bg = "NONE" },
          ModeMsg      = { fg = C.green,    bg = "NONE", bold = true },
          MoreMsg      = { fg = "#c2cef8",  bg = "NONE" },
          WarningMsg   = { fg = C.peach,    bg = "NONE" },
          ErrorMsg     = { fg = C.red,      bg = "NONE" },
          WinSeparator = { fg = C.surface1, bg = "NONE" },
        }
      end,
    },
    config = function(_, opts)
      -- your 16-color terminal palette
      local term = {
        "#2c2f40", "#e88295", "#8ad1bb", "#f4c99a",
        "#7eabf3", "#f4b8e4", "#a8e7dd", "#848faa",
        "#535a73", "#f26681", "#65c7a8", "#f4a88d",
        "#7daaee", "#efa7dc", "#a2e8e5", "#c2cef8",
      }

      local function apply_term_and_bg()
        for i = 0, 15 do vim.g["terminal_color_" .. i] = term[i + 1] end
        vim.g.terminal_color_foreground = "#d1d8f6"
        vim.g.terminal_color_background = "#1e1e27"

        if vim.env.NVIM_TRANSPARENT == "1" then
          vim.api.nvim_set_hl(0, "Normal",      { fg = "#d1d8f6", bg = "NONE" })
          vim.api.nvim_set_hl(0, "NormalFloat", { fg = "#d1d8f6", bg = "NONE" })
        else
          vim.api.nvim_set_hl(0, "Normal",      { fg = "#d1d8f6", bg = "#1e1e27" })
          vim.api.nvim_set_hl(0, "NormalFloat", { fg = "#d1d8f6", bg = "NONE" })
        end
      end

      require("catppuccin").setup(opts)

      -- Default boot
      vim.cmd.colorscheme("catppuccin")  -- flavour=frappe handles the variant
      apply_term_and_bg()

      -- Explicit switcher (so you can call it and be sure the palette is applied)
      vim.api.nvim_create_user_command("CatFrappe", function()
        vim.cmd.colorscheme("catppuccin-frappe")
        apply_term_and_bg()
      end, {})

      -- Also re-apply if you change scheme some other way
      vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("SuhailCatFrappe", { clear = true }),
        callback = function()
          if (vim.g.colors_name or ""):match("^catppuccin") then
            apply_term_and_bg()
          end
        end,
      })
    end,
  },
  -- Xcode theme (arzg/vim-colors-xcode) — available on demand
  {
    "arzg/vim-colors-xcode",
    name = "xcode",
    lazy = false,
    priority = 900,
    config = function()
      -- Xcode options you liked
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

      -- your Xcode DarkHC 16-color palette
      local term_darkhc = {
        "#2a2b3f", "#da8796", "#b5dde6", "#e6cba5",
        "#8da9e3", "#f4a5dc", "#97cde8", "#7c87a8",
        "#4c4e69", "#da8796", "#9ad9e6", "#e9ab92",
        "#87abf5", "#e176bf", "#73bade", "#c5cff5",
      }

      local function apply_xcode_darkhc_palette()
        for i = 0, 15 do vim.g["terminal_color_" .. i] = term_darkhc[i + 1] end
        vim.g.terminal_color_foreground = "#cfd6f5"
        vim.g.terminal_color_background = "#191821"

        if vim.env.NVIM_TRANSPARENT == "1" then
          vim.api.nvim_set_hl(0, "Normal",      { fg = "#cfd6f5", bg = "NONE" })
          vim.api.nvim_set_hl(0, "NormalFloat", { fg = "#cfd6f5", bg = "NONE" })
        else
          vim.api.nvim_set_hl(0, "Normal",      { fg = "#cfd6f5", bg = "#191821" })
          vim.api.nvim_set_hl(0, "NormalFloat", { fg = "#cfd6f5", bg = "NONE" })
        end

        -- optional: match README suggestion
        vim.api.nvim_set_hl(0, "Comment",        { italic = true })
        vim.api.nvim_set_hl(0, "SpecialComment", { italic = true })
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
        if variant == "darkhc" then
          apply_xcode_darkhc_palette()
        end
      end

      -- Commands
      vim.api.nvim_create_user_command("XcodeAuto",    function() use_xcode("auto")    end, {})
      vim.api.nvim_create_user_command("XcodeDark",    function() use_xcode("dark")    end, {})
      vim.api.nvim_create_user_command("XcodeDarkHC",  function() use_xcode("darkhc")  end, {})
      vim.api.nvim_create_user_command("XcodeLight",   function() use_xcode("light")   end, {})
      vim.api.nvim_create_user_command("XcodeLightHC", function() use_xcode("lighthc") end, {})
      vim.api.nvim_create_user_command("XcodeWWDC",    function() use_xcode("wwdc")    end, {})

      -- Keymaps (make DarkHC apply your palette too)
      vim.keymap.set("n", "<leader>th", function() use_xcode("darkhc") end, { desc = "Theme: Xcode Dark HC" })
      vim.keymap.set("n", "<leader>td", function() use_xcode("dark")   end, { desc = "Theme: Xcode Dark" })
      vim.keymap.set("n", "<leader>tl", function() use_xcode("light")  end, { desc = "Theme: Xcode Light" })
      vim.keymap.set("n", "<leader>tw", function() use_xcode("wwdc")   end, { desc = "Theme: Xcode WWDC" })

      -- In case you run :colorscheme xcodedarkhc manually, still apply your palette:
      vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("SuhailXcodeDarkHC", { clear = true }),
        callback = function()
          if (vim.g.colors_name or "") == "xcodedarkhc" then
            apply_xcode_darkhc_palette()
          end
        end,
      })
    end,
  },
}
