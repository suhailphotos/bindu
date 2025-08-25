-- Default: transparent ON unless user/export sets it.
if vim.env.NVIM_TRANSPARENT == nil then
  vim.env.NVIM_TRANSPARENT = "1"
end

-- Track the last applied state so we only re-run colorscheme when it changes.
vim.g._suhail_transparent_state = vim.env.NVIM_TRANSPARENT

-- Minimal apply that does NOT re-run :colorscheme
local function apply_transparent_highlights()
  if vim.env.NVIM_TRANSPARENT ~= "1" then return end
  for _, grp in ipairs({
    "Normal","NormalNC","NormalFloat","SignColumn","FoldColumn",
    "EndOfBuffer","NeoTreeNormal","NeoTreeNormalNC"
  }) do
    pcall(vim.api.nvim_set_hl, 0, grp, { bg = "NONE" })
  end
end

local function reapply_current_colorscheme()
  if vim.g.colors_name then
    vim.cmd("colorscheme " .. vim.g.colors_name)
  end
end

local function set_transparent(state)
  state = state and "1" or "0"
  if vim.env.NVIM_TRANSPARENT == state then
    -- No state change: just enforce highlight backgrounds (cheap, no recolor)
    apply_transparent_highlights()
    return
  end
  vim.env.NVIM_TRANSPARENT = state
  vim.g._suhail_transparent_state = state
  -- State changed: re-run colorscheme so theme/plugins rebuild highlights
  reapply_current_colorscheme()
end

vim.api.nvim_create_user_command("TransparentOn", function()
  set_transparent(true)
end, { desc = "Enable transparent backgrounds (respect terminal bg)" })

vim.api.nvim_create_user_command("TransparentOff", function()
  set_transparent(false)
end, { desc = "Disable transparent backgrounds" })

vim.api.nvim_create_user_command("TransparentToggle", function()
  set_transparent(vim.env.NVIM_TRANSPARENT ~= "1")
end, { desc = "Toggle transparent backgrounds" })

-- Optional: if a theme gets applied, enforce bg NONE when transparent is on.
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("SuhailGlobalTransparency", { clear = true }),
  callback = function()
    if vim.env.NVIM_TRANSPARENT == "1" then
      apply_transparent_highlights()
    end
  end,
})

-- Optional convenience if you ever want a “don’t re-run colorscheme; just make bg NONE” command
vim.api.nvim_create_user_command("TransparentApply", function()
  apply_transparent_highlights()
end, { desc = "Force bg=NONE on common UI groups without re-running colorscheme" })
