-- lua/suhail/lazy/colors.lua
--
-- WHAT THIS FILE DOES
--   • Declares/installs theme plugins only.
--   • Gives you two global knobs:
--       1) vim.g.theme_pairs       → which theme(s) to load (light/dark or one)
--       2) vim.g.theme_transparent → default transparency preference
--   • All polishing (statusline, comments, menu selection, EOB tildes, etc.)
--     is applied PER THEME (e.g. Nord) — not globally.
--
-- HOW TO SWITCH THEMES (quick)
--   1) In *any* Lua (e.g. your init.lua) set:
--        vim.g.theme_pairs = {
--          light = { theme = "catppuccin", variant = "latte",
--                    opts = { transparent_background = true, term_colors = true } },
--          dark  = { theme = "catppuccin", variant = "mocha",
--                    opts = { transparent_background = true, term_colors = true } },
--        }
--      Or use simple strings like "nord", "rose-pine-dawn", "tokyonight-moon".
--   2) Restart Neovim (or :ThemeAuto) — the switcher will apply it.
--
-- TEMPLATE FOR A PAIR (copy/paste, then edit)
--   vim.g.theme_pairs = {
--     light = { theme = "<family>", variant = "<variant>", opts = { /* theme-local opts */ } },
--     dark  = { theme = "<family>", variant = "<variant>", opts = { /* theme-local opts */ } },
--   }
--   Examples of <family>:
--     "lilac" (id or variant: "pearlbloom" → lilac-pearlbloom)
--     "catppuccin" (variant: "latte", "mocha", "frappe", "macchiato")
--     "tokyonight" (variant: "day", "night", "storm", "moon")
--     "rose-pine" (variant: "dawn", "moon"; plain "rose-pine" = main)
--     "nord", "xcode" (no variant), or a plain colorscheme string.
--
-- TRANSPARENCY
--   • Set BEFORE plugins load (e.g. at the top of init.lua):
--       vim.g.theme_transparent = true  -- or false
--   • Per-theme can still override via the per-theme "opts" you pass in the pair.
--
-- ADDING A BRAND-NEW THEME
--   1) Add its plugin spec below (so lazy.nvim installs it).
--   2) Add a loader in lua/suhail/theme_switcher.lua:
--        - extend `ensure_plugins_for(...)` with the new family name
--        - add an `apply_<family>(spec)` function and list it in `family_apply`
--   After that, you can reference it in vim.g.theme_pairs.

---------------------------------------------------------------------
-- 0) Global knobs
---------------------------------------------------------------------
vim.g.theme_transparent = (vim.g.theme_transparent ~= false)

---------------------------------------------------------------------
-- 1) Pair declaration (can be replaced anywhere before ThemeAuto)
---------------------------------------------------------------------
vim.g.theme_pairs = vim.g.theme_pairs or { light = "nord", dark = "nord" }

-- Optional env overrides (strings only; helpful for SSH)
if vim.env.NVIM_LILAC_LIGHT and vim.env.NVIM_LILAC_LIGHT ~= "" then
  vim.g.theme_pairs.light = vim.env.NVIM_LILAC_LIGHT
end
if vim.env.NVIM_LILAC_DARK and vim.env.NVIM_LILAC_DARK ~= "" then
  vim.g.theme_pairs.dark = vim.env.NVIM_LILAC_DARK
end

---------------------------------------------------------------------
-- 2) Plugins (each theme owns transparency & its own polish)
---------------------------------------------------------------------
return {
  -------------------------------------------------------------------
  -- Tokyonight
  -------------------------------------------------------------------
  {
    "folke/tokyonight.nvim",
    name = "tokyonight",
    lazy = true,
    opts = {
      style = "storm",
      transparent = vim.g.theme_transparent,
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
  -- Rose Pine
  -------------------------------------------------------------------
  {
    "rose-pine/neovim",
    name = "rose-pine",
    lazy = true,
    opts = {
      disable_background = vim.g.theme_transparent,
    },
  },

  -------------------------------------------------------------------
  -- Xcode (no extra polish)
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
  -- Nord (theme-local palette via vim.g.nord_ui)
  -------------------------------------------------------------------
  {
    "nordtheme/vim",
    name = "nord",
    lazy = false,
    priority = 1100,
    init = function()
      vim.g.nord_disable_background = vim.g.theme_transparent and 1 or 0
      vim.g.nord_contrast = 1
      vim.g.nord_borders = 0
      vim.g.nord_italic = 0
      vim.g.nord_bold = 1
      vim.g.nord_uniform_diff_background = 1
      vim.opt.termguicolors = true
    end,
    config = function()
      -- Your latest values kept intact (+ eob_fg for tildes)
      local ui = vim.tbl_deep_extend("force", {
        statusline_bg    = "#373c48",
        statusline_fg    = "#8f98aa",
        statusline_nc_fg = "#9aa3b1",
        relnum_dim       = "#474e5e",
        comment_fg       = "#7c869a",
        menu_sel_bg      = "#3a3f4b",
        menu_sel_fg      = "#e5e9f0",
        eob_fg           = "#474e5e",  -- ← EndOfBuffer "~" color
      }, vim.g.nord_ui or {})

      local function nord_polish()
        if (vim.g.colors_name or "") ~= "nord" then return end

        -- Accent overrides — your custom “greens” & “cyans”
        local green        = "#a8d8e1"  -- new green
        local green_bright = "#bae0e9"  -- bright green
        local cyan         = "#bd9ae5"  -- new cyan
        local cyan_bright  = "#b69ae5"  -- bright cyan

        -- Keep most UI transparent (IMPORTANT: do NOT clear PmenuSel)
        local clear = {
          "Normal","NormalNC","SignColumn","FoldColumn",
          "CursorLine","CursorColumn","WinSeparator",
          "NormalFloat","FloatBorder","FloatTitle",
          "Pmenu","PmenuSbar","PmenuThumb",
          "TelescopeNormal","TelescopeBorder",
          "TelescopePromptNormal","TelescopePromptBorder",
          "TelescopeResultsNormal","TelescopeResultsBorder",
          "TelescopePreviewNormal","TelescopePreviewBorder",
          "CmpDocumentation","CmpDocumentationBorder",
          -- EndOfBuffer: we’ll set its fg below (bg should stay transparent)
          "EndOfBuffer",
        }
        for _, g in ipairs(clear) do
          pcall(vim.api.nvim_set_hl, 0, g, { bg = "NONE", ctermbg = "NONE" })
        end

        -- 1) Syntax that’s green-ish in Nord (Strings, etc.)
        vim.api.nvim_set_hl(0, "String",     { fg = green,        bg = "NONE" })
        vim.api.nvim_set_hl(0, "Character",  { fg = green,        bg = "NONE" })
        pcall(vim.api.nvim_set_hl, 0, "@string",                   { fg = green })
        pcall(vim.api.nvim_set_hl, 0, "@string.documentation",     { fg = green })
        pcall(vim.api.nvim_set_hl, 0, "@string.special",           { fg = green_bright })
        pcall(vim.api.nvim_set_hl, 0, "@string.escape",            { fg = cyan_bright }) -- nice contrast for escapes/regex

        -- 2) Places where a “bright green” reads well (adds, OK diag)
        vim.api.nvim_set_hl(0, "DiffAdd",     { fg = green_bright, bg = "NONE", bold = true })
        vim.api.nvim_set_hl(0, "GitSignsAdd", { fg = green_bright, bg = "NONE" })
        -- Neovim 0.10+: DiagnosticOk exists; if not, it’s ignored
        pcall(vim.api.nvim_set_hl, 0, "DiagnosticOk", { fg = green_bright })

        -- 3) Cyan-ish buckets in Nord (specials/constants/hints)
        vim.api.nvim_set_hl(0, "Special",           { fg = cyan,       bg = "NONE" })
        vim.api.nvim_set_hl(0, "SpecialKey",        { fg = cyan,       bg = "NONE" })
        pcall(vim.api.nvim_set_hl, 0, "@constant",          { fg = cyan })
        pcall(vim.api.nvim_set_hl, 0, "@constant.builtin",  { fg = cyan_bright })
        vim.api.nvim_set_hl(0, "DiagnosticHint",    { fg = cyan,       bg = "NONE" })

        -- 4) Statusline
        vim.api.nvim_set_hl(0, "StatusLine",   { bg = ui.statusline_bg, fg = ui.statusline_fg })
        vim.api.nvim_set_hl(0, "StatusLineNC", { bg = ui.statusline_bg, fg = ui.statusline_nc_fg })

        -- 5) Rel. numbers & comments
        vim.api.nvim_set_hl(0, "LineNr",       { fg = ui.comment_fg, bg = "NONE" })
        vim.api.nvim_set_hl(0, "LineNrAbove",  { fg = ui.relnum_dim, bg = "NONE" })
        vim.api.nvim_set_hl(0, "LineNrBelow",  { fg = ui.relnum_dim, bg = "NONE" })
        vim.api.nvim_set_hl(0, "Comment",      { fg = ui.comment_fg, bg = "NONE", italic = false })
        pcall(vim.api.nvim_set_hl, 0, "@comment", { fg = ui.comment_fg, bg = "NONE", italic = false })

        -- 6) End-of-buffer tildes "~"
        vim.api.nvim_set_hl(0, "EndOfBuffer", { fg = ui.eob_fg, bg = "NONE" })

        -- Completion menu selection (visible on transparent popups)
        vim.api.nvim_set_hl(0, "PmenuSel", { bg = ui.menu_sel_bg, fg = ui.menu_sel_fg })
        pcall(vim.api.nvim_set_hl, 0, "CmpItemSel", { link = "PmenuSel" })
      end

      vim.api.nvim_create_autocmd("ColorScheme", { pattern = "nord", callback = nord_polish })
      nord_polish()
    end,
  },

  -------------------------------------------------------------------
  -- Catppuccin (transparent by default; variants via theme_pairs)
  -------------------------------------------------------------------
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = true,
    config = function()
      require("catppuccin").setup({
        transparent_background = vim.g.theme_transparent,
        term_colors = true,
      })
    end,
  },

  -------------------------------------------------------------------
  -- Lilac (your wrapper around Catppuccin; honors global transparency)
  -------------------------------------------------------------------
  {
    "suhailphotos/lilac",
    name = "lilac",
    lazy = true,
    config = function()
      local ok, lilac = pcall(require, "lilac")
      if ok and lilac.setup then
        lilac.setup({
          transparent = vim.g.theme_transparent,
          integrations = { treesitter = true, telescope = true, gitsigns = true, lsp_trouble = true },
        })
      end
    end,
  },
}
