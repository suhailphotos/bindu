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
    "gbprod/nord.nvim",
    name = "nord",
    lazy = false,          -- ensure it's configured before we might :colorscheme nord
    priority = 1100,
    opts = { transparent = true },
    config = function(_, opts)
      require("nord").setup(opts)
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

      local function detect_os_appearance()
        local env = (vim.env.NVIM_BG or ""):lower()
        if env == "dark" or env == "light" then return env end
        if vim.fn.has("mac") == 1 then
          local out = vim.fn.systemlist([[defaults read -g AppleInterfaceStyle 2>/dev/null]])[1]
          return (out == "Dark") and "dark" or "light"
        end
        return (vim.o.background == "light") and "light" or "dark"
      end

      -- If id starts with "lilac-", use lilac.load; otherwise :colorscheme <id>.
      local function load_for(bg)
        vim.o.background = bg
        local id = (bg == "dark") and DEFAULT_PALETTES.dark or DEFAULT_PALETTES.light
        if type(id) ~= "string" or id == "" then
          id = (bg == "dark") and "lilac-nightbloom" or "lilac-pearlbloom"
        end

        if id:match("^lilac%-") then
          lilac.setup({
            transparent = true,
            integrations = { treesitter = true, telescope = true, gitsigns = true, lsp_trouble = true },
          })
          lilac.load(id)
        else
          -- Non-Lilac schemes (e.g., "nord") are applied via :colorscheme
          local ok = pcall(vim.cmd.colorscheme, id)
          if not ok then
            vim.notify(("Colorscheme '%s' not found. Falling back to lilac."):format(id), vim.log.levels.WARN)
            lilac.setup({ transparent = true })
            lilac.load((bg == "dark") and "lilac-nightbloom" or "lilac-pearlbloom")
          end
        end
      end

      local function apply_auto()
        local want = detect_os_appearance()
        local target = (want == "dark") and DEFAULT_PALETTES.dark or DEFAULT_PALETTES.light
        local active = vim.g.colors_name or ""
        if active ~= target then
          load_for(want)
        end
      end

      -- initial apply + re-check on focus resume
      apply_auto()
      vim.api.nvim_create_autocmd({ "FocusGained", "VimResume" }, { callback = apply_auto })

      -- pairing helpers
      vim.api.nvim_create_user_command("LilacAuto", apply_auto, {})
      vim.api.nvim_create_user_command("LilacLight", function() load_for("light") end, {})
      vim.api.nvim_create_user_command("LilacDark",  function() load_for("dark")  end, {})
      vim.api.nvim_create_user_command("LilacPairStatus", function()
        local active = vim.g.colors_name or "(none)"
        local bg = (vim.o.background == "light") and "light" or "dark"
        local pair = ("light=%s  dark=%s"):format(DEFAULT_PALETTES.light, DEFAULT_PALETTES.dark)
        vim.notify(("Lilac pair: %s\nActive: %s (bg=%s)"):format(pair, active, bg))
      end, {})
      vim.api.nvim_create_user_command("LilacPairSet", function(opts)
        local args = {}
        for a in string.gmatch(opts.args or "", "%S+") do table.insert(args, a) end
        if #args ~= 2 then
          vim.notify("Usage: :LilacPairSet {light} {dark}", vim.log.levels.ERROR)
          return
        end
        DEFAULT_PALETTES.light, DEFAULT_PALETTES.dark = args[1], args[2]
        local bg = (vim.o.background == "light") and "light" or "dark"
        load_for(bg)
        vim.notify(("Lilac pair set: light=%s  dark=%s"):format(DEFAULT_PALETTES.light, DEFAULT_PALETTES.dark))
      end, { nargs = "*" })
      vim.api.nvim_create_user_command("LilacSame", function(opts)
        if not opts.args or opts.args == "" then
          vim.notify("Usage: :LilacSame {id}", vim.log.levels.ERROR)
          return
        end
        DEFAULT_PALETTES.light = opts.args
        DEFAULT_PALETTES.dark  = opts.args
        local bg = (vim.o.background == "light") and "light" or "dark"
        load_for(bg)
        vim.notify(("Lilac pair set to same: %s"):format(opts.args))
      end, { nargs = 1 })
    end,
  },
}
