# Colors & themes

Two modes:

- **ANSI mode (default)** — `mira` theme, `termguicolors = false`, only the 16 ANSI slots. Great for consistency across CLIs and TUIs.
- **Truecolor mode** — e.g. `nord`, `termguicolors = true`, full 24-bit color.

The switch is managed by `lua/suhail/theme.lua`.

---

## Commands & env

- `:ThemeUse mira` — ANSI mode (truecolor **off**), uses your 16-color palette.
- `:ThemeUse nord` — truecolor **on**.
- `:ThemeToggle` — toggles between the two.
- `:ThemeStatus` — prints the current theme and `termguicolors` state.

Default can be set with:

```lua
vim.g.theme_default = "mira"      -- or "nord"
-- or via environment:
NVIM_THEME=mira nvim
```

---

## How Mira uses ANSI

Mira maps **highlight groups** to **ANSI indices** (0–15) using `ctermfg`/`ctermbg`. Example snippets from the mapper:

```lua
-- UI
StatusLine    → ctermfg=4  ctermbg=0
StatusLineNC  → ctermfg=8  ctermbg=0
CursorLine    →            ctermbg=8
CursorLineNr  → ctermfg=7
LineNr        → ctermfg=8
Pmenu         → ctermfg=15 ctermbg=0
PmenuSel      → ctermfg=0  ctermbg=15

-- Syntax
Comment   → ctermfg=8
String    → ctermfg=2
Number    → ctermfg=3
Function  → ctermfg=4
Keyword   → ctermfg=5
Type      → ctermfg=11
Operator  → ctermfg=6
Constant  → ctermfg=12
```

Help buffer accents are also explicitly mapped (`helpHeader`, `helpHyperTextJump`, etc.) so `:help` and `:intro` look good in ANSI.

> Because only the **indices** are used, the exact shades come from your terminal’s 16-color palette. Tweak once at the terminal level and everything stays in sync.

---

## Truecolor themes

Switching to a truecolor theme (e.g. Nord) flips `termguicolors = true` and defers colors to the theme.

You can still add overrides with a `ColorScheme` autocmd:

```lua
-- Put this anywhere after theme.lua is required
vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "nord",
  callback = function()
    vim.api.nvim_set_hl(0, "CursorLineNr", { fg = "#ECEFF4", bold = false })
    vim.api.nvim_set_hl(0, "LineNr",       { fg = "#4C566A" })
    -- more tweaks here…
  end,
})
```

---

## Common tweaks (ANSI)

Want the **current line number** white and relatives dim? That’s already set:

```lua
CursorLineNr → ctermfg=7   -- white
LineNr       → ctermfg=8   -- bright black / gray
```

Change any group on the fly:

```vim
" example: make StatusLine brighter (ANSI index 15 on 0)
:hi StatusLine ctermfg=15 ctermbg=0
```

Persist it by adding the matching `set_hl` call in your Mira mapper (the one that sets ANSI indices).

---

## Adding another theme

1. Add the plugin in `lua/suhail/lazy/colors.lua`.
2. Add a family in `lua/suhail/theme.lua`:

```lua
mytheme = function()
  vim.opt.termguicolors = true
  pcall(vim.cmd.colorscheme, "mytheme")
  M.current = "mytheme"
  return true
end,
```

3. Optionally add it to the `:ThemeUse` completion list.

---

## Why ANSI by default?

- Consistency with terminals, CLI tools, and TUI apps that honor the first 16 slots.
- Seamless remote sessions (SSH) where truecolor/TERM quirks vary.
- Easy palette experiments: change 16 colors in the terminal once, and the whole stack follows.

Need full color? `:ThemeUse nord` and you’re done.
