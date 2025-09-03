-- lua/suhail/lazy/colors.lua
-- Theme plugins + a single place to declare your pair.
-- Transparency is configured INSIDE each theme, not in the switcher.

---------------------------------------------------------------------
-- 1) Declare the pair the switcher will use
---------------------------------------------------------------------
-- You can use either strings (colorscheme names) or tables:
--   { theme = "<family>", variant = "<name>", opts = { ... } }
--
-- Examples (uncomment one and comment the others to try):
--
-- -- A) Single theme everywhere (legacy string)
-- -- vim.g.theme_pairs = { light = "nord", dark = "nord" }
--
-- -- B) Single theme (Lilac variant)
-- -- vim.g.theme_pairs = {
-- --   light = { theme = "lilac", variant = "mistbloom" },
-- --   dark  = { theme = "lilac", variant = "mistbloom" },
-- -- }
--
-- -- C) Mix families: Lilac light, Catppuccin dark (with flavour)
-- -- NOTE: because the switcher calls catppuccin.setup(flavour=...),
-- --       include transparent_background in opts to keep transparency.
-- -- vim.g.theme_pairs = {
-- --   light = { theme = "lilac",      variant = "pearlbloom" },
-- --   dark  = { theme = "catppuccin", variant = "mocha",
-- --            opts = { transparent_background = true, term_colors = true } },
-- -- }
--
-- -- D) Mix Tokyonight & Rose Pine by variant
-- -- vim.g.theme_pairs = {
-- --   light = { theme = "rose-pine",  variant = "dawn" },
-- --   dark  = { theme = "tokyonight", variant = "moon" },
-- -- }
--
-- Default (you can change this any time):
vim.g.theme_pairs = vim.g.theme_pairs or { light = "nord", dark = "nord"}

-- Optional env overrides for quick swaps (strings only)
if vim.env.NVIM_LILAC_LIGHT and vim.env.NVIM_LILAC_LIGHT ~= "" then
  vim.g.theme_pairs.light = vim.env.NVIM_LILAC_LIGHT
end
if vim.env.NVIM_LILAC_DARK and vim.env.NVIM_LILAC_DARK ~= "" then
  vim.g.theme_pairs.dark = vim.env.NVIM_LILAC_DARK
end

---------------------------------------------------------------------
-- 2) Plugins (themes configure their OWN transparency here)
---------------------------------------------------------------------
return {
  -------------------------------------------------------------------
  -- Tokyonight (transparent)
  -------------------------------------------------------------------
  {
    "folke/tokyonight.nvim",
    name = "tokyonight",
    lazy = true,
    opts = {
      style = "storm",          -- you can still load -night/-moon variants via switcher
      transparent = true,       -- theme-owned transparency
      terminal_colors = true,
      styles = {
        comments = { italic = false },
        keywords = { italic = false },
        sidebars = "dark",
        floats = "dark",
      },
    },
  },

  -------------------------------------------------------------------
  -- Rose Pine (transparent via disable_background)
  -------------------------------------------------------------------
  {
    "rose-pine/neovim",
    name = "rose-pine",
    lazy = true,
    opts = {
      disable_background = true,   -- theme-owned transparency
      -- You can still load "rose-pine-dawn" / "rose-pine-moon" via switcher
    },
  },

  -------------------------------------------------------------------
  -- Xcode (left as-is; doesn’t force transparency)
  -------------------------------------------------------------------
  {
    "arzg/vim-colors-xcode",
    name = "xcode",
    lazy = true,
    config = function()
      local xopts = {
        green_comments = 0, dim_punctuation = 1,
        emph_types = 1, emph_funcs = 0, emph_idents = 0, match_paren_style = 0,
      }
      local function set_xcode_options()
        for _, v in ipairs({ "dark","darkhc","light","lighthc","wwdc" }) do
          for k, val in pairs(xopts) do vim.g["xcode"..v.."_"..k] = val end
        end
      end
      local function use_xcode(variant)
        set_xcode_options()
        local map = { auto="xcode", dark="xcodedark", darkhc="xcodedarkhc",
                      light="xcodelight", lighthc="xcodelighthc", wwdc="xcodewwdc" }
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

  -------------------------------------------------------------------
  -- Nord (transparent via official globals) — theme-owned
  -------------------------------------------------------------------
  {
    "nordtheme/vim",
    name = "nord",
    lazy = false,
    priority = 1100,
    init = function()
      vim.g.nord_disable_background = 1   -- keep everything else transparent
      vim.g.nord_contrast = 1
      vim.g.nord_borders = 0
      vim.g.nord_italic = 0
      vim.g.nord_bold = 1
      vim.g.nord_uniform_diff_background = 1
      vim.opt.termguicolors = true
    end,
    config = function()
      local function nord_polish()
        if (vim.g.colors_name or "") ~= "nord" then return end

        -- Keep most UI transparent (don’t touch statusline groups here)
        local clear = {
          "Normal","NormalNC","SignColumn","FoldColumn","EndOfBuffer",
          "CursorLine","CursorColumn","WinSeparator",
          "NormalFloat","FloatBorder","FloatTitle",
          "Pmenu","PmenuSel","PmenuSbar","PmenuThumb",
          "TelescopeNormal","TelescopeBorder",
          "TelescopePromptNormal","TelescopePromptBorder",
          "TelescopeResultsNormal","TelescopeResultsBorder",
          "TelescopePreviewNormal","TelescopePreviewBorder",
          "CmpDocumentation","CmpDocumentationBorder",
        }
        for _, g in ipairs(clear) do
          pcall(vim.api.nvim_set_hl, 0, g, { bg = "NONE", ctermbg = "NONE" })
        end

        -- Palette pulls from terminal where possible
        local ansi_black = vim.g.terminal_color_0  or "#000000"
        local ansi_white = vim.g.terminal_color_15 or "#d8dee9"
        local ansi_dim   = vim.g.terminal_color_8  or "#a3a7ad"  -- bright black

        -- Your slightly brighter tone for comments + current line number
        local dim = "#8f98aa"

        -- Statusline (solid)
        vim.api.nvim_set_hl(0, "StatusLine",   { bg = ansi_black, fg = dim })
        vim.api.nvim_set_hl(0, "StatusLineNC", { bg = ansi_black, fg = ansi_dim })

        -- Relative line numbers = ANSI 8
        vim.api.nvim_set_hl(0, "LineNr",       { fg = dim, bg = "NONE" })
        vim.api.nvim_set_hl(0, "LineNrAbove",  { fg = ansi_dim, bg = "NONE" })
        vim.api.nvim_set_hl(0, "LineNrBelow",  { fg = ansi_dim, bg = "NONE" })

        -- Current line number + comments = your custom dim hex
        vim.api.nvim_set_hl(0, "Comment",      { fg = dim, bg = "NONE", italic = false })
        pcall(vim.api.nvim_set_hl, 0, "@comment", { fg = dim, bg = "NONE", italic = false })
      end

      vim.api.nvim_create_autocmd("ColorScheme", { pattern = "nord", callback = nord_polish })
      nord_polish()
    end,  },
  -------------------------------------------------------------------
  -- Catppuccin (installed so you can select it directly)
  -- IMPORTANT:
  --  * If you pick Catppuccin with a VARIANT via the switcher, include
  --    opts = { transparent_background = true } in your theme_pairs entry.
  --    (The switcher calls catppuccin.setup({ flavour = ... }) in that case.)
  --  * If you pick plain "catppuccin" (no variant), this config keeps it transparent.
  -------------------------------------------------------------------
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = true,
    config = function()
      -- Default: transparent for the base "catppuccin" colorscheme.
      -- When the switcher later calls setup(flavour=...), include opts in theme_pairs
      -- to preserve transparency (see examples above).
      require("catppuccin").setup({
        transparent_background = true,
        term_colors = true,
        -- integrations can go here if you want them globally
      })
    end,
  },

  -------------------------------------------------------------------
  -- Lilac (your wrapper around Catppuccin; transparent by default)
  -------------------------------------------------------------------
  {
    "suhailphotos/lilac",
    name = "lilac",
    lazy = true,
    config = function()
      -- Your lilac/init.lua already defaults to transparent=true,
      -- but setting it here keeps that intent explicit.
      local ok, lilac = pcall(require, "lilac")
      if ok and lilac.setup then
        lilac.setup({
          transparent = true,
          integrations = { treesitter = true, telescope = true, gitsigns = true, lsp_trouble = true },
        })
      end
    end,
  },
}
