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
  -- Xcode theme (arzg/vim-colors-xcode) — available on demand
  {
    "arzg/vim-colors-xcode",
    name = "xcode",
    lazy = false,            -- load at startup so commands/keys work immediately
    priority = 900,          -- lower than catppuccin (which you set to 1000)
    config = function()
      -- Default Xcode options you can tweak (see README "Options")
      local xopts = {
        green_comments     = 0,  -- 0 or 1
        dim_punctuation    = 1,  -- 0 or 1
        emph_types         = 1,  -- 0 or 1
        emph_funcs         = 0,  -- 0 or 1
        emph_idents        = 0,  -- 0 or 1
        match_paren_style  = 0,  -- 0 or 1
      }

      -- Apply options for all variants so switches stay consistent
      local function set_xcode_options()
        for _, v in ipairs({ "dark", "darkhc", "light", "lighthc", "wwdc" }) do
          for k, val in pairs(xopts) do
            vim.g["xcode" .. v .. "_" .. k] = val
          end
        end
      end

      -- Transparency & small style touches when using Xcode
      local function post_touches()
        if vim.env.NVIM_TRANSPARENT == "1" then
          vim.api.nvim_set_hl(0, "Normal",      { bg = "none" })
          vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
        end
        -- Optional: italic comments like README suggests
        vim.api.nvim_set_hl(0, "Comment",        { italic = true })
        vim.api.nvim_set_hl(0, "SpecialComment", { italic = true })
      end

      -- Core switcher
      local function use_xcode(variant)
        set_xcode_options()
        local map = {
          auto    = "xcode",          -- follows :set background
          dark    = "xcodedark",
          darkhc  = "xcodedarkhc",
          light   = "xcodelight",
          lighthc = "xcodelighthc",
          wwdc    = "xcodewwdc",
        }
        vim.cmd.colorscheme(map[variant] or "xcodedark")
        post_touches()
      end

      -- User commands
      vim.api.nvim_create_user_command("XcodeAuto",   function() use_xcode("auto")    end, {})
      vim.api.nvim_create_user_command("XcodeDark",   function() use_xcode("dark")    end, {})
      vim.api.nvim_create_user_command("XcodeDarkHC", function() use_xcode("darkhc")  end, {})
      vim.api.nvim_create_user_command("XcodeLight",  function() use_xcode("light")   end, {})
      vim.api.nvim_create_user_command("XcodeLightHC",function() use_xcode("lighthc") end, {})
      vim.api.nvim_create_user_command("XcodeWWDC",   function() use_xcode("wwdc")    end, {})

      -- Quick toggles
      vim.keymap.set("n", "<leader>td", function() use_xcode("dark")    end, { desc = "Theme: Xcode Dark" })
      vim.keymap.set("n", "<leader>th", function() use_xcode("darkhc")  end, { desc = "Theme: Xcode Dark HC" })
      vim.keymap.set("n", "<leader>tl", function() use_xcode("light")   end, { desc = "Theme: Xcode Light" })
      vim.keymap.set("n", "<leader>tw", function() use_xcode("wwdc")    end, { desc = "Theme: Xcode WWDC" })
      vim.keymap.set("n", "<leader>tc", function() vim.cmd.colorscheme("catppuccin") end, { desc = "Theme: Catppuccin" })

      -- If you ever want Xcode as default at startup:
      -- use_xcode("dark")  -- (comment out your catppuccin colorscheme call)
    end,
  },
}
