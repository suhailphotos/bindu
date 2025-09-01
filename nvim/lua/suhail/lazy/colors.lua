-- lua/suhail/lazy/colors.lua
--[[
LILAC PAIRING (read me)

Set your default light/dark palettes here. You can point both to the same ID
to use a single look for light *and* dark. Example presets:
  light = "lilac-pearlbloom",  dark = "lilac-nightbloom"       -- different
  light = "lilac-mistbloom",   dark = "lilac-mistbloom"        -- same for both
  light = "lilac-emberbloom",  dark = "lilac-mistbloom"        -- mix & match

Runtime behavior:
  • Background detection order:
      1) NVIM_BG="light"|"dark" (handy over SSH)
      2) macOS AppleInterfaceStyle (Dark → "dark", otherwise "light")
      3) current :set background
  • Optional per-session overrides (also nice over SSH):
      NVIM_LILAC_LIGHT="<id>"  NVIM_LILAC_DARK="<id>"
    If set, they replace the defaults below for this session only.

Useful commands:
  :LilacList                → list available palettes
  :Lilac <id>               → preview any palette immediately
  :LilacAuto                → re-run detection and load the paired palette
  :LilacLight               → force-load DEFAULT_PALETTES.light
  :LilacDark                → force-load DEFAULT_PALETTES.dark
  :LilacPairStatus          → show current pair + active palette
  :LilacPairSet {light} {dark}
                            → set the pair for this session & apply current bg
  :LilacSame {id}           → set both light/dark to one id (session only)
  :TransparentToggle / :TransparentOn / :TransparentOff

Tip: run :LilacList to see all IDs, e.g. lilac-pearlbloom, lilac-nightbloom,
     lilac-mistbloom (and future lilac-emberbloom).
]]

local DEFAULT_PALETTES = {
  light = "lilac-pearlbloom",
  dark  = "lilac-nightbloom",
}

-- Optional per-session overrides via env (great over SSH)
if vim.env.NVIM_LILAC_LIGHT and vim.env.NVIM_LILAC_LIGHT ~= "" then
  DEFAULT_PALETTES.light = vim.env.NVIM_LILAC_LIGHT
end
if vim.env.NVIM_LILAC_DARK and vim.env.NVIM_LILAC_DARK ~= "" then
  DEFAULT_PALETTES.dark = vim.env.NVIM_LILAC_DARK
end

-- (kept for completeness; used only if you flip NVIM_TRANSPARENT=1)
local function ColorMyPencils(color)
  if vim.env.NVIM_TRANSPARENT == "1" then
    color = color or "rose-pine"
    vim.cmd.colorscheme(color)
    vim.api.nvim_set_hl(0, "Normal",      { bg = "none" })
    vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
  end
end

return {
  -- Optional alternatives (unchanged)
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

  -- Lilac (default)
  {
    "suhailphotos/lilac",
    name = "lilac",
    lazy = false,
    priority = 1200,
    dependencies = { "catppuccin/nvim" },
    config = function()
      local lilac = require("lilac")

      -- ---------- helpers ----------
      local function detect_os_appearance()
        local env = (vim.env.NVIM_BG or ""):lower()
        if env == "dark" or env == "light" then return env end
        if vim.fn.has("mac") == 1 then
          local out = vim.fn.systemlist([[defaults read -g AppleInterfaceStyle 2>/dev/null]])[1]
          return (out == "Dark") and "dark" or "light"
        end
        return (vim.o.background == "light") and "light" or "dark"
      end

      local function palette_exists(id)
        local ok, F = pcall(require, "lilac.flavors")
        return ok and F.index and F.index[id] ~= nil
      end

      local function pick_id_for(bg)
        local id = (bg == "dark") and DEFAULT_PALETTES.dark or DEFAULT_PALETTES.light
        if palette_exists(id) then return id end
        -- fallback to well-known defaults if someone fat-fingers an id
        local fallback = (bg == "dark") and "lilac-nightbloom" or "lilac-pearlbloom"
        vim.notify(("Lilac: unknown palette '%s', using '%s'"):format(tostring(id), fallback), vim.log.levels.WARN)
        return fallback
      end

      local function load_for(bg)
        vim.o.background = bg
        local id = pick_id_for(bg)
        lilac.setup({
          transparent = true,
          integrations = { treesitter = true, telescope = true, gitsigns = true, lsp_trouble = true },
        })
        lilac.load(id)
      end

      local function apply_auto()
        local want = detect_os_appearance()
        local have = (vim.o.background == "light") and "light" or "dark"
        local is_lilac = (vim.g.colors_name or ""):match("^lilac%-")
        if (want ~= have) or not is_lilac then
          load_for(want)
        end
      end

      -- ---------- initial apply ----------
      apply_auto()

      -- re-check when focus returns (e.g. you toggled OS theme)
      vim.api.nvim_create_autocmd({ "FocusGained", "VimResume" }, {
        callback = apply_auto,
      })

      -- ---------- commands ----------
      vim.api.nvim_create_user_command("LilacAuto", apply_auto, {})

      vim.api.nvim_create_user_command("LilacLight", function()
        load_for("light")
      end, {})

      vim.api.nvim_create_user_command("LilacDark", function()
        load_for("dark")
      end, {})

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
        -- apply immediately to the current background
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

      -- Status & transparency toggles (as before)
      vim.api.nvim_create_user_command("LilacStatus", function()
        local name = vim.g.colors_name or "(none)"
        local okF, F = pcall(require, "lilac.flavors")
        local flav = (okF and F.index[name] and F.index[name].variant) or "?"
        local trans = (lilac._opts and lilac._opts.transparent) and "on" or "off"
        vim.notify(("Lilac: %s  •  base=%s  •  transparent=%s"):format(name, flav, trans))
      end, {})

      vim.api.nvim_create_user_command("LilacTransparentToggle", lilac.toggle_transparent, {})
      vim.api.nvim_create_user_command("TransparentToggle",      lilac.toggle_transparent, {})
      vim.api.nvim_create_user_command("TransparentOn", function()
        lilac.setup({ transparent = true })
        lilac.load(vim.g.colors_name or pick_id_for((vim.o.background == "light") and "light" or "dark"))
      end, {})
      vim.api.nvim_create_user_command("TransparentOff", function()
        lilac.setup({ transparent = false })
        lilac.load(vim.g.colors_name or pick_id_for((vim.o.background == "light") and "light" or "dark"))
      end, {})
    end,
  },
}
