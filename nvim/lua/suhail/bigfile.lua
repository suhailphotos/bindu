-- lua/suhail/bigfile.lua
local M = {}

local LIMIT_BYTES = 1 * 1024 * 1024  -- 1MB
local LIMIT_LINES = 10000

local function bufname(bufnr)
  return vim.api.nvim_buf_get_name(bufnr)
end

local function is_big_by_size(bufnr)
  local name = bufname(bufnr)
  if name == "" then return false end -- unnamed/new buffers
  local size = vim.fn.getfsize(name)
  return size > LIMIT_BYTES
end

local function is_big_by_lines(bufnr)
  -- Only reliable after the file is read
  return vim.api.nvim_buf_line_count(bufnr) > LIMIT_LINES
end

local function disable_heavy_stuff(bufnr)
  -- Detach LSP from THIS buffer (don't stop the client!)
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
    pcall(vim.lsp.buf_detach_client, bufnr, client.id)
  end

  -- Disable diagnostics just for this buffer
  vim.diagnostic.enable(false, { bufnr = bufnr })

  -- Optional: mark buffer so other configs can check it
  vim.b[bufnr].bigfile = true
end

function M.setup()
  -- Fast path: size check before reading
  vim.api.nvim_create_autocmd("BufReadPre", {
    callback = function(args)
      local bufnr = args.buf
      if is_big_by_size(bufnr) then
        disable_heavy_stuff(bufnr)
      end
    end,
    desc = "Bigfile: disable LSP/diagnostics early by filesize",
  })

  -- Safety net: line-count check after reading (covers small-but-huge-lines cases)
  vim.api.nvim_create_autocmd("BufReadPost", {
    callback = function(args)
      local bufnr = args.buf
      if vim.b[bufnr].bigfile then return end
      if is_big_by_lines(bufnr) then
        disable_heavy_stuff(bufnr)
      end
    end,
    desc = "Bigfile: disable LSP/diagnostics by linecount",
  })
end

return M
