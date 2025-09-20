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
      -- <<< NO automatic popup >>>
      completion = { autocomplete = false },
      mapping = cmp.mapping.preset.insert({
        ["<C-Space>"] = cmp.mapping.complete(),           -- manual menu
        ["<CR>"]      = cmp.mapping.confirm({ select = true }),
        ["<C-n>"]     = cmp.mapping.select_next_item(),
        ["<C-p>"]     = cmp.mapping.select_prev_item(),
        ["<C-e>"]     = cmp.mapping.abort(),
      }),
      sources = cmp.config.sources(
        { { name = "nvim_lsp" }, { name = "luasnip" } },
        { { name = "buffer" }, { name = "path" } }
      ),
    })

    -- Punctuation-driven “on demand” triggers:
    local function should_trigger_for(ch)
      if ch == "." then return true end               -- Python/JS/TS/Rust/etc.
      if vim.bo.filetype == "rust" and ch == ":" then
        -- trigger on the second ":" in "::"
        local col = vim.api.nvim_win_get_cursor(0)[2]
        local line = vim.api.nvim_get_current_line()
        local prev = (col > 0) and line:sub(col, col) or ""
        return prev == ":"
      end
      return false
    end

    -- Fire completion right after the char is inserted.
    vim.api.nvim_create_autocmd("InsertCharPre", {
      callback = function()
        local ch = vim.v.char
        if should_trigger_for(ch) then
          vim.schedule(function()
            if not cmp.visible() then cmp.complete() end
          end)
        end
      end,
    })
  end,
}
