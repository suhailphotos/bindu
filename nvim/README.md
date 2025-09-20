# Suhail’s Neovim

Minimal core, fast startup, and portable across macOS + Linux. Two big ideas:

- **ANSI-first defaults** with the `mira` theme (truecolor off), so terminals, CLIs, and TUI tools “just match” with a 16-color palette.
- **Portable Python host** selection that plays nicely with `uv`, Conda, and system Pythons—no machine-specific hardcoding.

## Layout

```
nvim/
├─ init.lua
├─ lazy-lock.json
└─ lua/suhail
   ├─ lazy/          # plugin specs (lazy.nvim)
   │  ├─ colors.lua  # theme plugins (mira, nord, etc.)
   │  ├─ devicons.lua
   │  ├─ init.lua
   │  ├─ telescope.lua
   │  └─ yazi.lua
   ├─ lazy_init.lua  # lazy.nvim bootstrap/setup
   ├─ pythonhost.lua # portable Python host resolver + :PythonHostStatus
   ├─ remap.lua      # generic keymaps (plugin-free)
   ├─ set.lua        # core options
   └─ theme.lua      # theme loader & :ThemeUse/:ThemeToggle
```

## First run

- macOS bootstrap is handled by Ansible (Homebrew, uv, Ghostty/iTerm assets, etc.).
- Neovim plugins install headlessly via `lazy.nvim` on first launch.
- Default theme is **Mira** (ANSI). Toggle with `:ThemeToggle` or `:ThemeUse nord`.

## Docs

- **Python host** (how Neovim picks `/usr/bin/python3`, Conda, or `~/.venvs/nvim` and how to fix `pynvim`):  
  [`docs/Pythonhost.md`](docs/Pythonhost.md)
- **Colors / themes** (ANSI palette mapping, truecolor themes, how overrides work):  
  [`docs/Colors.md`](docs/Colors.md)

## Health checks

- `:checkhealth` — full diag
- `:PythonHostStatus` — what interpreter Neovim will use
- `:PythonHostCheck` — verifies `pynvim` is importable and offers a fix
