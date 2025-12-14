-- lua/suhail/lazy/cmd.lua
return {
  "hrsh7th/nvim-cmp",
  event = "InsertEnter",
  dependencies = {
    "hrsh7th/cmp-nvim-lsp",
    "L3MON4D3/LuaSnip",
    "saadparwaiz1/cmp_luasnip",
    "hrsh7th/cmp-buffer",
    "hrsh7th/cmp-path",

    -- For Cargo.toml completion:
    -- NOTE: crates.nvim itself is already in your plugin list; this is only the cmp source.
    "saecki/crates.nvim",
  },
  config = function()
    local cmp = require("cmp")
    local luasnip = require("luasnip")

    --------------------------------------------------------------------------
    -- Base cmp setup (manual popup by default)
    --------------------------------------------------------------------------
    cmp.setup({
      preselect = cmp.PreselectMode.None,

      -- Manual by default (no auto-popup)
      completion = { autocomplete = {} },

      snippet = {
        expand = function(args) luasnip.lsp_expand(args.body) end,
      },

      mapping = cmp.mapping.preset.insert({
        ["<C-Space>"] = cmp.mapping.complete(), -- open menu on demand

        ["<CR>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.confirm({ select = false }) -- don’t auto-accept first item
          else
            fallback()
          end
        end, { "i", "s" }),

        ["<C-n>"] = cmp.mapping.select_next_item(),
        ["<C-p>"] = cmp.mapping.select_prev_item(),
        ["<C-e>"] = cmp.mapping.abort(),
      }),

      sources = cmp.config.sources(
        { { name = "nvim_lsp" }, { name = "luasnip" } },
        { { name = "buffer" }, { name = "path" } }
      ),
    })

    --------------------------------------------------------------------------
    -- Filetype: TOML (Cargo.toml) → enable crates completion
    --------------------------------------------------------------------------
    cmp.setup.filetype("toml", {
      sources = cmp.config.sources(
        { { name = "crates" } },
        { { name = "nvim_lsp" }, { name = "buffer" }, { name = "path" } }
      ),
    })

    --------------------------------------------------------------------------
    -- Session toggles
    --------------------------------------------------------------------------
    -- 1) Auto-popup toggle (typing shows menu). Default OFF each session.
    vim.g.cmp_autocomplete_enabled = false
    local function set_auto(on)
      local ev = cmp.TriggerEvent.TextChanged
      cmp.setup({ completion = { autocomplete = on and { ev } or {} } })
      vim.g.cmp_autocomplete_enabled = on
      vim.notify("cmp auto: " .. (on and "ON" or "OFF"))
    end
    vim.api.nvim_create_user_command("CmpAutoOn", function() set_auto(true) end, {})
    vim.api.nvim_create_user_command("CmpAutoOff", function() set_auto(false) end, {})
    vim.api.nvim_create_user_command("CmpToggleAuto", function()
      set_auto(not vim.g.cmp_autocomplete_enabled)
    end, {})

    -- 2) Optional punctuation trigger ('.' and Rust '::'). Default OFF.
    vim.g.cmp_punct_triggers = false
    vim.api.nvim_create_user_command("CmpTogglePunct", function()
      vim.g.cmp_punct_triggers = not vim.g.cmp_punct_triggers
      vim.notify("cmp punctuation: " .. (vim.g.cmp_punct_triggers and "ON" or "OFF"))
    end, {})

    vim.api.nvim_create_autocmd("InsertCharPre", {
      desc = "Optional dot/:: trigger for cmp",
      callback = function()
        if not vim.g.cmp_punct_triggers then return end

        local ch = vim.v.char
        if ch == "." then
          vim.schedule(function()
            if not cmp.visible() then cmp.complete() end
          end)
          return
        end

        if vim.bo.filetype == "rust" and ch == ":" then
          local col = vim.api.nvim_win_get_cursor(0)[2]
          local line = vim.api.nvim_get_current_line()
          local prev = (col > 0) and line:sub(col, col) or ""
          if prev == ":" then
            vim.schedule(function()
              if not cmp.visible() then cmp.complete() end
            end)
          end
        end
      end,
    })
  end,
}
