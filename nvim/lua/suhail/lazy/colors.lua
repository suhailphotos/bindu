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
  -- Optional alternatives
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

  -- Xcode (load on demand)
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

  -- Lilac (default) — Catppuccin is a dependency, not a separate plugin block
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

      local function load_lilac_for(bg)
        vim.o.background = bg
        local id = (bg == "dark") and "lilac-nightbloom" or "lilac-pearlbloom"
        lilac.setup({
          transparent = true,
          integrations = { treesitter = true, telescope = true, gitsigns = true, lsp_trouble = true },
        })
        lilac.load(id)
      end

      local function apply_auto()
        local want = detect_os_appearance()
        local have = (vim.o.background == "light") and "light" or "dark"
        if (want ~= have) or not ((vim.g.colors_name or ""):match("^lilac%-")) then
          load_lilac_for(want)
        end
      end

      -- ---------- initial apply ----------
      apply_auto()

      -- Re-check when focus returns (e.g., you toggled OS theme)
      vim.api.nvim_create_autocmd({ "FocusGained", "VimResume" }, {
        callback = function() apply_auto() end,
      })

      -- Handy commands
      vim.api.nvim_create_user_command("LilacAuto", apply_auto, {})
      vim.api.nvim_create_user_command("LilacLight", function() load_lilac_for("light") end, {})
      vim.api.nvim_create_user_command("LilacDark",  function() load_lilac_for("dark")  end, {})

      -- Status & transparency toggles you already had
      vim.api.nvim_create_user_command("LilacStatus", function()
        local name = vim.g.colors_name or "(none)"
        local okF, F = pcall(require, "lilac.flavors")
        local flav = (okF and F.index[name] and F.index[name].variant) or "?"
        local trans = (lilac._opts and lilac._opts.transparent) and "on" or "off"
        vim.notify(("Lilac: %s  •  base=%s  •  transparent=%s"):format(name, flav, trans))
      end, {})

      vim.api.nvim_create_user_command("LilacTransparentToggle", function()
        lilac.toggle_transparent()
      end, {})
      vim.api.nvim_create_user_command("TransparentToggle", function()
        lilac.toggle_transparent()
      end, {})
      vim.api.nvim_create_user_command("TransparentOn", function()
        lilac.setup({ transparent = true })
        lilac.load(vim.g.colors_name or "lilac-nightbloom")
      end, {})
      vim.api.nvim_create_user_command("TransparentOff", function()
        lilac.setup({ transparent = false })
        lilac.load(vim.g.colors_name or "lilac-nightbloom")
      end, {})
    end,
  },
}
