-- NvChad-style Telescope highlights, with ANSI-aware colors
local M = {}

local function hl(name) return vim.api.nvim_get_hl(0, { name = name, link = false }) or {} end
local function set(name, spec) vim.api.nvim_set_hl(0, name, spec) end

function M.apply()
  local normal = hl("Normal")
  local visual = hl("Visual")
  local string = hl("String")
  local err    = hl("Error")

  -- GUI (truecolor) fallback uses theme-derived colors
  local fg     = normal.fg
  local bg     = normal.bg
  local bg_alt = visual.bg or bg
  local green  = string.fg or fg
  local red    = err.fg or fg

  local gui = vim.opt.termguicolors:get()

  if gui then
    -- Truecolor themes: mimic NvChad recipe (borderless + colored titles)
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

    set("TelescopeResultsTitle",   { fg = bg,     bg = bg })   -- hidden
    set("TelescopePromptTitle",    { fg = bg,     bg = red })  -- red pill
    set("TelescopePreviewTitle",   { fg = bg,     bg = green })-- green pill
  else
    -- ANSI mode (Mira): explicit cterm indices
    -- background = black (0); search/prompt strip = bright black (8)
    set("TelescopeBorder",         { ctermfg = 0, ctermbg = 0 })
    set("TelescopeResultsBorder",  { ctermfg = 0, ctermbg = 0 })
    set("TelescopePreviewBorder",  { ctermfg = 0, ctermbg = 0 })
    set("TelescopePromptBorder",   { ctermfg = 8, ctermbg = 8 })

    set("TelescopeNormal",         {               ctermbg = 0 })
    set("TelescopeResultsNormal",  {               ctermbg = 0 })
    set("TelescopePreviewNormal",  {               ctermbg = 0 })
    set("TelescopePromptNormal",   { ctermfg = 7,  ctermbg = 8 }) -- white on bright-black

    set("TelescopePromptPrefix",   { ctermfg = 1,  ctermbg = 8 }) -- red on bright-black
    set("TelescopeSelection",      {               ctermbg = 8 }) -- row highlight

    set("TelescopeResultsTitle",   { ctermfg = 0,  ctermbg = 0 }) -- hidden
    set("TelescopePromptTitle",    { ctermfg = 0,  ctermbg = 1 }) -- "red pill"
    set("TelescopePreviewTitle",   { ctermfg = 0,  ctermbg = 2 }) -- "green pill"
  end
end

vim.api.nvim_create_autocmd({ "ColorScheme", "VimEnter" }, {
  callback = function() pcall(M.apply) end,
  desc = "Apply NvChad-style Telescope highlights",
})

return M
