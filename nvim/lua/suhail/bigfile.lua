local M = {}

local LIMIT_BYTES = 1 * 1024 * 1024  -- 1MB; tune to taste
local LIMIT_LINES = 10000            -- or line-based cut-off

local function is_big(buf)
  local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(buf))
  if ok and stats and stats.size and stats.size > LIMIT_BYTES then return true end
  if vim.api.nvim_buf_line_count(buf) > LIMIT_LINES then return true end
  return false
end

function M.setup()
  vim.api.nvim_create_autocmd("BufReadPre", {
    callback = function(args)
      local b = args.buf
      if not is_big(b) then return end

      -- Disable expensive stuff for this buffer
      vim.b.bigfile = true
      pcall(function() require("nvim-treesitter.configs").setup({ highlight = { enable = false }, indent = { enable = false } }) end)
      vim.cmd("syntax off")

      -- If you had LSP on, turn it off for this buffer:
      if not vim.g.lsp_muted then
        for _, c in ipairs(vim.lsp.get_clients({ bufnr = b })) do c.stop(true) end
      end

      -- Helpful UI tweaks
      vim.bo.swapfile = false
      vim.bo.undofile = false
      vim.opt_local.foldmethod = "manual"
    end,
  })
end

return M
