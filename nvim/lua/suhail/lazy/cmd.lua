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
  },
  config = function()
    local cmp = require("cmp")
    local luasnip = require("luasnip")

    cmp.setup({
      preselect = cmp.PreselectMode.None,
      -- Manual by default (no auto-popup)
      completion = { autocomplete = {} },  -- most bulletproof “manual only”
      mapping = cmp.mapping.preset.insert({
        ["<C-Space>"] = cmp.mapping.complete(),  -- open menu on demand
        ["<CR>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.confirm({ select = false })     -- don’t auto-accept first item
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
    -- Session toggles
    --------------------------------------------------------------------------
    -- 1) Auto-popup toggle (typing shows menu). Default OFF each session.
    vim.g.cmp_autocomplete_enabled = false
    local function set_auto(on)
      local ev = require("cmp").TriggerEvent.TextChanged
      require("cmp").setup({ completion = { autocomplete = on and { ev } or {} } })
      vim.g.cmp_autocomplete_enabled = on
      vim.notify("cmp auto: " .. (on and "ON" or "OFF"))
    end
    vim.api.nvim_create_user_command("CmpAutoOn",      function() set_auto(true)  end, {})
    vim.api.nvim_create_user_command("CmpAutoOff",     function() set_auto(false) end, {})
    vim.api.nvim_create_user_command("CmpToggleAuto",  function() set_auto(not vim.g.cmp_autocomplete_enabled) end, {})

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
          vim.schedule(function() if not cmp.visible() then cmp.complete() end end)
        elseif vim.bo.filetype == "rust" and ch == ":" then
          local col = vim.api.nvim_win_get_cursor(0)[2]
          local line = vim.api.nvim_get_current_line()
          local prev = (col > 0) and line:sub(col, col) or ""
          if prev == ":" then
            vim.schedule(function() if not cmp.visible() then cmp.complete() end end)
          end
        end
      end,
    })
  end,
}
