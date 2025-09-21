local M = {}

local LIMIT_BYTES = 1 * 1024 * 1024  -- 1MB
local LIMIT_LINES = 10000

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

      vim.b[b].bigfile = true

      -- Stop Treesitter for this buffer only
      pcall(function() vim.treesitter.stop(b) end)

      -- Turn off classic syntax too
      vim.bo[b].syntax = "off"

      -- LSP off just for this buffer (if currently on)
      if not vim.g.lsp_muted then
        for _, c in ipairs(vim.lsp.get_clients({ bufnr = b })) do c.stop(true) end
      end

      -- Lightweight buffer opts
      vim.bo[b].swapfile = false
      vim.bo[b].undofile = false
      vim.bo[b].indentexpr = ""
      vim.wo.foldmethod = "manual"
    end,
  })
end

return M
