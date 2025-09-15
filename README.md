# bindu

**bindu** = “the dot.” This is my single-branch dotfiles repo. The **`main`** branch maps directly to `~/.config/` on every machine.

> TL;DR  
> - The repo root mirrors `~/.config` (Neovim, tmux, Ghostty, Starship, etc.).  
> - **Pixi** manages non‑Python CLIs/libs globally via a per‑host manifest you track here.  
> - **uv** manages Python: project envs live in `~/.venvs/<project>`; global Python tools are installed with `uv tool` and exposed via a clean shim dir.  
> - This README is the landing page; deep dives live in `pixi/` and `uv/` subfolders and `docs/`.

---

## Architecture (who owns what)

- **Pixi** → non‑Python libs & CLIs you want anywhere without activating envs.  
  Examples: `ffmpeg`, `imagemagick`, `poppler`, `p7zip`, `openimageio`, `libvips`.  
  - Each host has a tiny Stow package in `~/.config/pixi/hosts/<host>/.pixi/manifests/pixi-global.toml`.  
  - On a host, Stow links it to `~/.pixi/manifests/pixi-global.toml`, and `pixi global list` shows what’s exposed on `$PATH` (`~/.pixi/bin`).

- **uv** → Python interpreters, per‑project virtual envs, and global Python *tools*.  
  Examples: `uv tool install lumiera` gives a `lumiera` on `$PATH`.  
  - Project envs are external (Orbit sets `UV_PROJECT_ENVIRONMENT`) at `~/.venvs/<project>`.  
  - Global tools install into `~/.local/share/uv/tools/<tool>` and are exposed by shims in **`~/.local/share/uv/bin`** (kept separate from the `tools/` tree).

- **Bindu** (this repo) → the source of truth for both worlds:  
  - **Pixi**: all per‑host manifests live under `pixi/hosts/` and are linked with GNU Stow.  
  - **uv**: docs & runbooks live under `uv/` so the workflows are repeatable across machines.

Nothing under `~/.pixi/` or `~/.local/share/uv/tools/` is tracked—only the manifests and docs.

---

## Layout (top‑level highlights)

The repo root mirrors `~/.config`:

```
nvim/        # Neovim config
tmux/        # tmux.conf etc.
ghostty/     # terminal settings
starship/    # prompt/theming
eza/         # ls replacement theme
fzf/, ripgrep/, yazi/, ...

pixi/        # Pixi global tooling (per‑host manifests + README)
uv/          # uv + Orbit docs (project envs & global tool mgmt)
docs/        # extra runbooks (e.g., Homebrew housekeeping)
```

Quick docs index:

- **Pixi** → [`pixi/README.md`](pixi/README.md) (per‑host global tools with Stow)  
- **uv (project envs & global tools)** → [`uv/README.md`](uv/README.md)  
  - New package under Matrix → [`uv/AddEnv.md`](uv/AddEnv.md)  
  - Global uv tools → [`uv/UVToolManage.md`](uv/UVToolManage.md)  
- **Homebrew housekeeping** → [`docs/Brewhouse.md`](docs/Brewhouse.md)

---

## Install (no Ansible)

```bash
git clone https://github.com/suhailphotos/bindu.git ~/.bindu
git -C ~/.bindu checkout --detach             # allow main to be used by a worktree
git -C ~/.bindu worktree add ~/.config main   # ~/.config is now a clean worktree
```

Update later:

```bash
git -C ~/.bindu fetch origin
git -C ~/.config pull --ff-only
```

### With Ansible

My playbook ensures `~/.config` is a git worktree pulled from `bindu:main`, then sets up Ghostty/iTerm, Neovim, tmux, Starship, etc.

**Notes**

- Using a worktree keeps `~/.config` clean and versioned.  
- If you previously hosted `~/.config` from another repo, detach that worktree first:

```bash
git -C ~/.helix worktree remove -f ~/.config || true
```

---

## First‑run steps (per host)

1) **Pixi (global tools)**
   - Install Pixi without touching your shell rc (Orbit handles `$PATH`):
     ```bash
     curl -fsSL https://pixi.sh/install.sh | env PIXI_NO_PATH_UPDATE=1 zsh
     mkdir -p "$HOME/.pixi/manifests"
     stow -d "$HOME/.config/pixi/hosts" -t "$HOME" -R "$(hostname -s)"
     pixi global list
     ```
   - Details and seeding scripts: see [`pixi/README.md`](pixi/README.md).

2) **uv (Python)**
   - Nothing to “install” here beyond uv itself. Orbit sets:
     - external project envs at `~/.venvs/<project>`
     - global tool shims at `~/.local/share/uv/bin`  
   - Workflows & knobs: see [`uv/README.md`](uv/README.md).

---

## Everyday quickrefs

- **Create a new Python package under Matrix + Orbit helper** → see [`uv/AddEnv.md`](uv/AddEnv.md).  
- **Install/upgrade/remove a global Python CLI** → see [`uv/UVToolManage.md`](uv/UVToolManage.md).  
- **Add/remove a global non‑Python tool** → edit this host’s Pixi manifest; see [`pixi/README.md`](pixi/README.md).

---

## About Homebrew config

Homebrew does **not** read configuration from `~/.config/brew` or `XDG_CONFIG_HOME`. It’s driven by environment variables (e.g., `HOMEBREW_*`) and command flags, plus optional `Brewfile`s when you use `brew bundle`. So a `~/.config/brew/` folder is fine for **notes**, but Homebrew itself won’t consume anything from there. See the `brew` manpage for supported environment variables. For housekeeping/migration notes, use [`docs/Brewhouse.md`](docs/Brewhouse.md).

---

## Conventions & assumptions

- `$XDG_CONFIG_HOME` is set (defaults to `~/.config`).  
- Orbit is installed separately and sourced from your shell (manages uv env selection, PATH hygiene, and helper functions).  
- Host‑specific config lives under `pixi/hosts/<host>` and is applied with GNU Stow.

---

## License

MIT
