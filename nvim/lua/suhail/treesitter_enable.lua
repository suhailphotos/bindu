-- lua/suhail/treesitter_enable.lua
-- Enable Tree-sitter highlighting reliably across mac + linux + containers.

-- 1) If nvim-treesitter.configs exists, configure it (no installs at startup).
do
  local ok, configs = pcall(require, "nvim-treesitter.configs")
  if ok then
    configs.setup({
      ensure_installed = {},
      sync_install = false,
      auto_install = false,
      highlight = {
        enable = true,
        additional_vim_regex_highlighting = false,
      },
      indent = { enable = true },
    })
  end
end

-- 2) Always start TS per-buffer when filetype is set.
--    This is what makes `:Inspect` show Treesitter: ... and makes the highlighter "active".
local group = vim.api.nvim_create_augroup("SuhailTSAutostart", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  group = group,
  callback = function(ev)
    if vim.bo[ev.buf].buftype ~= "" then return end
    pcall(vim.treesitter.start, ev.buf)
  end,
})
