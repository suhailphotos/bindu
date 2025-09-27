-- NvChad-style Telescope highlights (ANSI-aware) + visible title "pills"
local M = {}

local function hl(name) return vim.api.nvim_get_hl(0, { name = name, link = false }) or {} end
local function set(name, spec) vim.api.nvim_set_hl(0, name, spec) end

local function apply_truecolor()
  local normal = hl("Normal")
  local visual = hl("Visual")
  local string = hl("String")
  local err    = hl("Error")
  local fg, bg = normal.fg, normal.bg
  local bg_alt = visual.bg or bg
  local green  = string.fg or fg
  local red    = err.fg or fg

  set("TelescopeBorder",         { fg = bg,     bg = bg })
  set("TelescopeResultsBorder",  { fg = bg,     bg = bg })
  set("TelescopePreviewBorder",  { fg = bg,     bg = bg })
  set("TelescopePromptBorder",   { fg = bg_alt, bg = bg_alt })

  set("TelescopeNormal",         { bg = bg })
  set("TelescopeResultsNormal",  { bg = bg })
  set("TelescopePreviewNormal",  { bg = bg })
  set("TelescopePromptNormal",   { fg = fg,     bg = bg_alt })

  set("TelescopePromptPrefix",   { fg = red,    bg = bg_alt })
  set("TelescopeSelection",      { bg = bg_alt })

  -- title "pills"
  set("TelescopePromptTitle",    { fg = bg, bg = red })
  set("TelescopePreviewTitle",   { fg = bg, bg = green })
  -- leave Results pill visible (matches NvChad look when enabled)
  set("TelescopeResultsTitle",   { fg = bg, bg = bg_alt })
end

local function apply_ansi()
  -- ANSI 0 = black, 8 = bright black
  local PROMPT = tonumber(vim.g.telescope_prompt_idx or 233) -- darker-than-bg
  local SELECT = tonumber(vim.g.telescope_select_idx or 235) -- selection row

  set("TelescopeBorder",         { ctermfg = PROMPT, ctermbg = PROMPT })
  set("TelescopeResultsBorder",  { ctermfg = PROMPT, ctermbg = PROMPT })
  set("TelescopePreviewBorder",  { ctermfg = PROMPT, ctermbg = PROMPT })
  set("TelescopePromptBorder",   { ctermfg = SELECT, ctermbg = SELECT })

  set("TelescopeNormal",         {               ctermbg = PROMPT })
  set("TelescopeResultsNormal",  {               ctermbg = PROMPT })
  set("TelescopePreviewNormal",  {               ctermbg = PROMPT })
  set("TelescopePromptNormal",   { ctermfg = 7,  ctermbg = SELECT }) -- white on bright-black

  set("TelescopePromptPrefix",   { ctermfg = 1,  ctermbg = SELECT }) -- red on bright-black
  set("TelescopeSelection",      {               ctermbg = SELECT })

  -- title "pills"
  set("TelescopePromptTitle",    { ctermfg = PROMPT, ctermbg = 1 })  -- red pill
  set("TelescopePreviewTitle",   { ctermfg = PROMPT, ctermbg = 2 })  -- green pill
  set("TelescopeResultsTitle",   { ctermfg = 7, ctermbg = SELECT })  -- optional second header bar
end

function M.apply()
  if vim.opt.termguicolors:get() then apply_truecolor() else apply_ansi() end
end

vim.api.nvim_create_autocmd({ "ColorScheme", "VimEnter" }, {
  callback = function() pcall(M.apply) end,
  desc = "Apply NvChad-style Telescope highlights",
})

return M
