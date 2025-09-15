# uv Tool Management (Global CLIs)

How to keep **global uv tools** clean and fully separated from everything else.

## Goals

- Tool **envs** live under `UV_TOOL_DIR` (default: `~/.local/share/uv/tools/<tool>`).
- Tool **shims** (the runnable commands) live under a **separate bin dir**, e.g. `~/.local/share/uv/bin`.
- Your `$PATH` includes only that shim dir—**not** `…/tools/bin`.

> uv exposes tools through shims (symlinks) on Unix. There isn’t a “no‑shim install” mode. If you want zero shims, use `uvx <tool>` aliases instead.

---

## Orbit setup (once)

In `modules/env/35-uv.zsh`:

```zsh
# Where uv stores tool envs
export UV_TOOL_DIR="${UV_TOOL_DIR:-$HOME/.local/share/uv/tools}"

# Keep shims separate from everything else (outside tools/)
export UV_TOOL_BIN_DIR="${UV_TOOL_BIN_DIR:-$HOME/.local/share/uv/bin}"

# Ensure the shim dir exists early and is first on PATH
mkdir -p "$UV_TOOL_BIN_DIR"
path=("$UV_TOOL_BIN_DIR" ${path:#$UV_TOOL_BIN_DIR})
```

Reload:

```zsh
source "$ORBIT_HOME/core/bootstrap.zsh"
```

**Do not** add `$(uv tool dir)/bin` to your PATH. uv scans `…/tools/` for tools; a `bin/` inside it looks like a broken tool.

---

## Install / list / upgrade / remove

```zsh
# Install (shim goes to $UV_TOOL_BIN_DIR)
uv tool install lumiera

# List
uv tool list

# Upgrade one or all
uv tool upgrade lumiera
uv tool upgrade --all

# Reinstall
uv tool install --reinstall lumiera

# Uninstall
uv tool uninstall lumiera
```

### One-off run (no shim)
```zsh
uvx lumiera --help
```

---

## Rehome existing shims (from ~/.local/bin)

If you previously installed tools before setting `UV_TOOL_BIN_DIR`, you may have shims in `~/.local/bin`.

```zsh
# Uninstall and reinstall so shims land in the new bin
uv tool uninstall lumiera
uv tool install lumiera
```

If any old symlinks remain, remove them:

```zsh
rm -f ~/.local/bin/lumiera
rehash   # or: hash -r
```

---

## Verify

```zsh
# Check PATH contains your shim dir
echo "$PATH" | tr ':' '\n' | grep -Fx "$UV_TOOL_BIN_DIR"

# Which binary will run
type -a lumiera

# Inspect the shim
ls -l "$UV_TOOL_BIN_DIR/lumiera"
# → lumiera -> ~/.local/share/uv/tools/lumiera/bin/lumiera
```

---

## Common warnings & fixes

- **warning: “`…/uv/bin` is not on your PATH”**  
  It just means the shim dir didn’t exist in PATH at install time. Ensure the Orbit snippet above runs **before** installs, then reinstall.

- **warning: Ignoring malformed tool `bin`**  
  You accidentally created `~/.local/share/uv/tools/bin/`. Remove it:
  ```zsh
  uv tool uninstall bin   # cleans the dangling env
  ```
  Don’t create any directory inside `…/tools/` manually.

---

## Optional: No-install alias

If you prefer not to install a shim at all:

```zsh
# runs the latest lumiera each time without a global shim
alias lumiera='uvx lumiera'
```

This keeps your PATH pristine. uv caches envs so subsequent runs are fast.

---

## Troubleshooting

```zsh
# Where shims go
echo "$UV_TOOL_BIN_DIR"

# Where uv keeps tool envs
uv tool dir

# Print tool list in JSON (for scripting)
uv tool list --json
```
