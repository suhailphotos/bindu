-- --------------------------------------------------
-- Theme Loader
-- --------------------------------------------------
local M = {}

-- Map of theme families → apply function
M._families = {
  mira = function()
    local ok = pcall(require, "mira"); if not ok then return false, "mira not installed" end
    vim.g.mira_ansi_only = true
    vim.opt.termguicolors = false
    pcall(vim.cmd.colorscheme, "mira")
    M.current = "mira"
    return true
  end,

  nord = function()
    vim.opt.termguicolors = true
    pcall(vim.cmd.colorscheme, "nord")
    M.current = "nord"
    return true
  end,

  ["rose-pine"] = function()
    -- Ensure plugin is loaded and reset its variant
    local ok, rp = pcall(require, "rose-pine")
    if ok and rp and rp.setup then
      local v = vim.g.rose_pine_default_variant or "main"  -- change if you prefer
      rp.setup({ variant = v, dark_variant = v })
    end

    vim.cmd("hi clear")         -- fully clear previous hi groups
    vim.opt.termguicolors = true
    pcall(vim.cmd.colorscheme, "rose-pine")
    M.current = "rose-pine"
    return true
  end,
}

function M.use(name)
  local fn = M._families[name]
  if not fn then
    vim.notify("Unknown theme: " .. tostring(name), vim.log.levels.WARN)
    return
  end
  local ok, err = fn()
  if not ok then
    vim.notify("Theme '" .. name .. "' failed: " .. (err or ""), vim.log.levels.ERROR)
  end
end

function M.toggle()
  if M.current == "mira" then
    M.use("nord")
  else
    M.use("mira")
  end
end

function M.apply_default()
  -- Choose default from env or a global; fallback to mira (ANSI)
  local want = vim.g.theme_default or vim.env.NVIM_THEME or "mira"
  M.use(want)
end

-- make :ThemeUse completion dynamic
vim.api.nvim_create_user_command("ThemeUse", function(opts) M.use(opts.args) end, {
  nargs = 1,
  complete = function() return M.list() end,  -- ← includes rose-pine now
})

vim.api.nvim_create_user_command("ThemeToggle", function() M.toggle() end, {})
vim.api.nvim_create_user_command("ThemeStatus", function()
  vim.notify(("Theme: %s\ntermguicolors=%s"):format(M.current or "(none)", tostring(vim.o.termguicolors)))
end, {})

-- --------------------------------------------------
-- Optional: register keymaps here (not in remap.lua)
-- --------------------------------------------------
local function register_keymaps()
  local function map(lhs, cmd, desc)
    vim.keymap.set("n", lhs, function() pcall(vim.cmd, cmd) end, { desc = desc, silent = true })
  end
  map("<leader>tm", "ThemeUse mira", "Theme: Mira (ANSI)")
  map("<leader>tn", "ThemeUse nord", "Theme: Nord (truecolor)")
  map("<leader>tt", "ThemeToggle",   "Theme: toggle")
end

-- Opt-out knob: set this to false anywhere before loading theme.lua if you
-- don't want the theme keys at all.
if vim.g.theme_enable_keymaps ~= false then
  register_keymaps()
end

-- List all theme names you defined in M._families
function M.list()
  local names = {}
  for k, _ in pairs(M._families) do table.insert(names, k) end
  table.sort(names)
  return names
end

return M
