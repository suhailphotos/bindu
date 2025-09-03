-- lua/suhail/theme_switcher.lua
-- Variant-aware, theme-agnostic switcher. No bg/fg/highlight tweaks here.

local M = {}

-- --- Helpers ---------------------------------------------------------------

local function read_pairs()
  local p = vim.g.theme_pairs or {}
  return p.light or "nord", p.dark or "nord"
end

local function pick_spec(light, dark)
  -- If both specs are the same (string compare or table deep equal), just use one.
  local function eq(a, b)
    if type(a) ~= type(b) then return false end
    if type(a) == "table" then
      for k, v in pairs(a) do if b[k] ~= v then return false end end
      for k, v in pairs(b) do if a[k] ~= v then return false end end
      return true
    end
    return a == b
  end
  if eq(light, dark) then return dark end

  local env = (vim.env.NVIM_BG or ""):lower()
  if env == "light" then return light end
  if env == "dark"  then return dark  end
  -- optional macOS fallback; uncomment if you want it:
  -- if vim.fn.has("mac") == 1 then
  --   local out = vim.fn.systemlist([[defaults read -g AppleInterfaceStyle 2>/dev/null]])[1]
  --   local want = (out == "Dark") and "dark" or "light"
  --   return (want == "dark") and dark or light
  -- end
  return dark
end

-- Normalize a user spec into a canonical table:
--   Input: "nord" | "rose-pine-dawn" | {theme="catppuccin", variant="mocha"} | {theme="lilac", id="lilac-pearlbloom"}
--   Output: { family=<string>, id=<string>|nil, variant=<string>|nil, opts=<table>|nil }
local function norm(spec)
  if type(spec) == "table" then
    return {
      family  = spec.theme or spec.family, -- "lilac","catppuccin","tokyonight","rose-pine","nord","xcode",...
      id      = spec.id,                   -- direct colorscheme or lilac id
      variant = spec.variant,              -- "mocha","latte","night","storm","dawn","moon","pearlbloom",...
      opts    = spec.opts,                 -- optional theme-local options (we pass only what's needed)
    }
  end

  -- string
  local s = tostring(spec)

  if s:match("^lilac%-") then
    return { family = "lilac", id = s }
  end
  if s:match("^rose%-pine") then
    -- "rose-pine" | "rose-pine-dawn" | "rose-pine-moon"
    return { family = "rose-pine", id = s }
  end
  if s:match("^tokyonight") then
    -- "tokyonight" | "tokyonight-night" | "tokyonight-storm" | "tokyonight-day" | "tokyonight-moon"
    return { family = "tokyonight", id = s }
  end
  if s:match("^xcode") then
    return { family = "xcode", id = s }
  end
  if s == "nord" then
    return { family = "nord", id = "nord" }
  end
  if s == "catppuccin" then
    return { family = "catppuccin", variant = nil } -- will use default flavour
  end

  -- Default: assume it's a plain colorscheme name.
  return { family = "colorscheme", id = s }
end

local function ensure_plugins_for(family, id)
  local wants = {}
  if family == "lilac" then
    table.insert(wants, "lilac")
    table.insert(wants, "catppuccin") -- lilac depends on it
  elseif family == "catppuccin" then
    table.insert(wants, "catppuccin")
  elseif family == "tokyonight" then
    table.insert(wants, "tokyonight")
  elseif family == "rose-pine" then
    table.insert(wants, "rose-pine")
  elseif family == "nord" then
    table.insert(wants, "nord")
  elseif family == "xcode" then
    table.insert(wants, "xcode")
  elseif family == "colorscheme" then
    -- heuristic: try to load a matching plugin by name if we know it
    if id and id:match("^tokyonight") then table.insert(wants, "tokyonight") end
    if id and id:match("^rose%-pine") then table.insert(wants, "rose-pine") end
    if id == "nord" then table.insert(wants, "nord") end
    if id and id:match("^xcode") then table.insert(wants, "xcode") end
    if id == "catppuccin" then table.insert(wants, "catppuccin") end
  end
  if #wants > 0 then pcall(require("lazy").load, { plugins = wants }) end
end

-- --- Family applicators -----------------------------------------------------

local function apply_lilac(spec)
  ensure_plugins_for("lilac")
  local ok, lilac = pcall(require, "lilac")
  if not ok then return end
  local id = spec.id or (spec.variant and ("lilac-" .. spec.variant)) or "lilac-nightbloom"
  -- Do NOT set transparency here; lilac’s own setup controls that.
  lilac.load(id)
end

local function apply_catppuccin(spec)
  ensure_plugins_for("catppuccin")
  local flavour = spec.variant and tostring(spec.variant)
  if flavour then
    -- Use the variant-specific scheme; preserves plugin config (transparency)
    local cs = "catppuccin-" .. flavour
    if pcall(vim.cmd.colorscheme, cs) then return end
  end
  -- Fallback to base scheme if variant name isn't available
  pcall(vim.cmd.colorscheme, "catppuccin")
end

local function apply_tokyonight(spec)
  ensure_plugins_for("tokyonight")
  -- Prefer the variant-specific colorscheme name (no setup override).
  if spec.variant then
    local cs = "tokyonight-" .. spec.variant
    if pcall(vim.cmd.colorscheme, cs) then return end
  end
  -- Fallback: generic name
  pcall(vim.cmd.colorscheme, spec.id or "tokyonight")
end

local function apply_rose_pine(spec)
  ensure_plugins_for("rose-pine")
  local cs = (spec.variant == "dawn" and "rose-pine-dawn")
          or (spec.variant == "moon" and "rose-pine-moon")
          or (spec.id or "rose-pine")
  pcall(vim.cmd.colorscheme, cs)
end

local function apply_nord(_spec)
  ensure_plugins_for("nord")
  pcall(vim.cmd.colorscheme, "nord")
end

local function apply_xcode(spec)
  ensure_plugins_for("xcode")
  pcall(vim.cmd.colorscheme, spec.id or "xcodedark")
end

local function apply_colorscheme(spec)
  ensure_plugins_for("colorscheme", spec.id)
  pcall(vim.cmd.colorscheme, spec.id)
end

local family_apply = {
  lilac       = apply_lilac,
  catppuccin  = apply_catppuccin,
  tokyonight  = apply_tokyonight,
  ["rose-pine"] = apply_rose_pine,
  nord        = apply_nord,
  xcode       = apply_xcode,
  colorscheme = apply_colorscheme,
}

-- --- Public ----------------------------------------------------------------

local function apply_spec(spec)
  local s = norm(spec)
  local fn = family_apply[s.family or "colorscheme"] or apply_colorscheme
  fn(s)
end

function M.apply()
  local light, dark = read_pairs()
  local pick = pick_spec(light, dark)
  apply_spec(pick)
end

-- Commands (unchanged UX; still simple)
vim.api.nvim_create_user_command("ThemeStatus", function()
  local active = vim.g.colors_name or "(none)"
  local light, dark = read_pairs()
  local mode = (type(light) == "table" and type(dark) == "table" and
               vim.inspect(light) == vim.inspect(dark))
               or (type(light) ~= "table" and type(dark) ~= "table" and light == dark)
               and "single" or "pair"
  vim.notify(("Active: %s\nMode: %s\nLight: %s\nDark:  %s")
    :format(active, mode, vim.inspect(light), vim.inspect(dark)))
end, {})

vim.api.nvim_create_user_command("ThemeAuto", function() M.apply() end, {})

-- Keep simple setters; you can still pass strings or tables via Lua elsewhere.
vim.api.nvim_create_user_command("ThemeSet", function(opts)
  local a, b = opts.args:match("^(%S+)%s+(%S+)$")
  if not (a and b) then
    vim.notify("Usage: :ThemeSet {light} {dark}  (use Lua to set tables)", vim.log.levels.ERROR)
    return
  end
  vim.g.theme_pairs = { light = a, dark = b }
  M.apply()
end, { nargs = "*" })

vim.api.nvim_create_user_command("ThemeSame", function(opts)
  local id = (opts.args or "") ~= "" and opts.args or nil
  if not id then
    local _, dark = read_pairs()
    id = dark
  end
  vim.g.theme_pairs = { light = id, dark = id }
  apply_spec(id)
end, { nargs = "?" })

vim.api.nvim_create_user_command("ThemeLight", function()
  local light = read_pairs()
  apply_spec(light)
end, {})

vim.api.nvim_create_user_command("ThemeDark", function()
  local _, dark = read_pairs()
  apply_spec(dark)
end, {})

return M
