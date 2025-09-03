-- lua/suhail/lazy/colors.lua
--[[
LILAC PAIRING (read me)

Set your default light/dark palettes here. You can point both to the same ID
to use a single look for light *and* dark. Example presets:
  light = "lilac-pearlbloom",  dark = "lilac-nightbloom"       -- different
  light = "lilac-mistbloom",   dark = "lilac-mistbloom"        -- same for both
  light = "nord",              dark = "lilac-nightbloom"       -- mix external + Lilac

Runtime behavior:
  • Background detection order:
      1) NVIM_BG="light"|"dark" (handy over SSH)
      2) macOS AppleInterfaceStyle (Dark → "dark", otherwise "light")
      3) current :set background
  • Optional per-session overrides (also nice over SSH):
      NVIM_LILAC_LIGHT="<id>"  NVIM_LILAC_DARK="<id>"
    If set, they replace the defaults below for this session only.

Useful commands:
  :Lilac <id>               → preview any Lilac palette immediately (e.g. lilac-nightbloom)
  :LilacAuto                → re-run detection and load the paired palette
  :LilacLight               → force-load DEFAULT_PALETTES.light
  :LilacDark                → force-load DEFAULT_PALETTES.dark
  :LilacPairStatus          → show current pair + active palette
  :LilacPairSet {light} {dark}
                            → set the pair for this session & apply current bg
  :LilacSame {id}           → set both light/dark to one id (session only)
]]

local DEFAULT_PALETTES = {
  -- choose any combination: "nord" or a Lilac id like "lilac-nightbloom"
  light = "nord",
  dark  = "nord",
}

-- Optional per-session overrides via env (great over SSH)
if vim.env.NVIM_LILAC_LIGHT and vim.env.NVIM_LILAC_LIGHT ~= "" then
  DEFAULT_PALETTES.light = vim.env.NVIM_LILAC_LIGHT
end
if vim.env.NVIM_LILAC_DARK and vim.env.NVIM_LILAC_DARK ~= "" then
  DEFAULT_PALETTES.dark = vim.env.NVIM_LILAC_DARK
end

return {
  -- Optional alternatives kept lazy (unchanged)
  {
    "folke/tokyonight.nvim",
    name = "tokyonight",
    lazy = true,
    opts = {
      style = "storm",
      transparent = true,
      terminal_colors = true,
      styles = {
        comments = { italic = false },
        keywords = { italic = false },
        sidebars = "dark",
        floats = "dark",
      },
    },
  },
  {
    "rose-pine/neovim",
    name = "rose-pine",
    lazy = true,
    opts = { disable_background = true },
  },
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

  ---------------------------------------------------------------------------
  -- Nord: stock setup (transparency only). We don't apply the scheme here.
  ---------------------------------------------------------------------------
  {
    "nordtheme/vim",
    name = "nord",
    lazy = false,          -- make sure it’s available before we might :colorscheme nord
    priority = 1100,
    -- For Vimscript colorschemes, set globals *before* applying the scheme.
    init = function()
      -- keep the “transparent” feel you had before
      vim.g.nord_disable_background = 1
      -- tasteful defaults; tweak if you like
      vim.g.nord_contrast = 1
      vim.g.nord_borders = 0
      vim.g.nord_italic = 0
      vim.g.nord_bold = 1
      vim.g.nord_uniform_diff_background = 1
      -- truecolor helps Nord look right
      vim.opt.termguicolors = true
    end,
  },

  ---------------------------------------------------------------------------
  -- Lilac: driver for lilac-* palettes + auto light/dark pairing
  ---------------------------------------------------------------------------
  {
    "suhailphotos/lilac",
    name = "lilac",
    lazy = false,
    priority = 1200,
    dependencies = { "catppuccin/nvim" },
    config = function()
      local lilac = require("lilac")

      local function is_lilac(id)
        return type(id) == "string" and id:match("^lilac%-")
      end

      -- Single-theme: hard rule for bg (no OS/env checks).
      -- Treat only pearlbloom as "light"; everything else as "dark".
      local function fixed_bg_for_single(id)
        if id == "lilac-pearlbloom" then return "light" end
        return "dark"
      end

      local function load_one(id, bg)
        vim.o.background = bg
        if is_lilac(id) then
          lilac.setup({
            transparent = true,
            integrations = { treesitter = true, telescope = true, gitsigns = true, lsp_trouble = true },
          })
          lilac.load(id)
        else
          pcall(vim.cmd.colorscheme, id)
        end
      end

      local function detect_os_bg()
        local env = (vim.env.NVIM_BG or ""):lower()
        if env == "light" or env == "dark" then return env end
        if vim.fn.has("mac") == 1 then
          local out = vim.fn.systemlist([[defaults read -g AppleInterfaceStyle 2>/dev/null]])[1]
          return (out == "Dark") and "dark" or "light"
        end
        return (vim.o.background == "light") and "light" or "dark"
      end

      local function load_pair()
        local want = detect_os_bg()
        local id = (want == "dark") and DEFAULT_PALETTES.dark or DEFAULT_PALETTES.light
        load_one(id, want)
      end

      local SINGLE = (DEFAULT_PALETTES.light == DEFAULT_PALETTES.dark)

      if SINGLE then
        -- SINGLE THEME: ignore OS + NVIM_BG; pick a fixed bg for that theme
        local id = DEFAULT_PALETTES.dark
        local bg = fixed_bg_for_single(id)
        load_one(id, bg)

        -- Optional helper to change the single theme at runtime
        vim.api.nvim_create_user_command("LilacSame", function(opts)
          local new = (opts.args or "") ~= "" and opts.args or id
          DEFAULT_PALETTES.light, DEFAULT_PALETTES.dark = new, new
          load_one(new, fixed_bg_for_single(new))
        end, { nargs = "?" })
      else
        -- PAIR MODE: follow OS light/dark (or NVIM_BG)
        load_pair()
        vim.api.nvim_create_autocmd({ "FocusGained", "VimResume" }, { callback = load_pair })
        vim.api.nvim_create_user_command("LilacAuto",  load_pair, {})
        vim.api.nvim_create_user_command("LilacLight", function()
          load_one(DEFAULT_PALETTES.light, "light")
        end, {})
        vim.api.nvim_create_user_command("LilacDark",  function()
          load_one(DEFAULT_PALETTES.dark, "dark")
        end, {})
      end
    end,
  },
}
