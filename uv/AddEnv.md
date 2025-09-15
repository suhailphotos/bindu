# Orbit + uv: Creating a New Python Package

A quick guide for making a new Python package that plays nicely with **Orbit** and **uv**.

> TL;DR — Packages live at `$DROPBOX/matrix/packages/<name>`. Initialize with `uv init`, add the name to Orbit’s project list, and push Orbit so other machines get the helper on next shell start.

---

## Where packages live

- **Root**: `$MATRIX` → usually `$DROPBOX/matrix`
- **Packages**: `$MATRIX/packages/<package_name>`
- **Orbit repo**: `$MATRIX/orbit` (alias: `orbit`)

Orbit generates helper functions for your packages so you can just type the package name to jump in and activate the env (e.g., `usdUtils`). Those functions are derived from a list in Orbit’s config.

---

## Prereqs

- Orbit is installed and sourced in your shell (`$ORBIT_HOME/core/bootstrap.zsh`).
- `uv` is installed and on `PATH`.
- Optional: Houdini/Nuke installed if your package needs them.

---

## Initialize the package

You can make the project **in-place** under `packages/` (recommended), or create elsewhere and move it in.

### Option A — Create directly under `packages/` (recommended)

```bash
# Jump to packages folder
packages

# Create and initialize the project
mkdir notionUtils
cd notionUtils
uv init

# (Optional) immediately create env & install (Orbit stores envs at ~/.venvs/<name>)
uv venv     # or: uv sync / uv lock / uv run -- python -V
```

### Option B — Create elsewhere then move (legacy habit)

```bash
# Make scaffold outside first (if you prefer)
mkdir -p ~/Desktop/notionUtils_temp
cd ~/Desktop/notionUtils_temp
uv init

# Move into Matrix packages
mv ~/Desktop/notionUtils_temp "$DROPBOX/matrix/packages/notionUtils"
cd "$DROPBOX/matrix/packages/notionUtils"
```

**What `uv init` does:** writes the scaffold files (`pyproject.toml`, `README.md`, `.python-version`, etc.).

**When the env is created:** on the first `uv venv`, `uv sync`, `uv run`, or `uv lock`.

> Orbit sets `UV_PROJECT_ENVIRONMENT` so project envs live in `~/.venvs/<project>`.  
> If you want an in-repo `.venv` for a specific project:
> ```bash
> UV_PROJECT_ENVIRONMENT="$PWD/.venv" uv venv
> ```

---

## Add the new package to Orbit’s project list

Orbit exposes per-project helper functions (e.g., `Incept`, `Lumiera`, …) from a single list.
Edit **`$ORBIT_HOME/modules/env/45-projects.zsh`** and add your package name:

```zsh
# modules/env/45-projects.zsh
typeset -ga ORBIT_PROJECTS=(
  usdUtils
  oauthManager
  pythonKitchen
  ocioTools
  helperScripts
  Incept
  pariVaha
  Lumiera
  Ledu
  hdrUtils
  notionUtils          # ← add yours here
)
```

> If the package needs Houdini by default, also add its name to the `HOU_PACKAGES` array so `pkg` will automatically do `hou use`:
> - Add to **`$ORBIT_HOME/secrets/.env`** (recommended, not tracked), then reload your shell:
>   ```zsh
>   HOU_PACKAGES=(houdiniLab houdiniUtils notionUtils)
>   ```

Reload Orbit so the new helper exists immediately:

```zsh
source "$ORBIT_HOME/core/bootstrap.zsh"
# now you can run:
notionUtils
```

---

## Update & push Orbit (so other machines get it)

Orbit is a git repo. Push your change so the bootstrap in `~/.zshrc` on other machines will pull it automatically.

```bash
orbit                              # alias → $MATRIX/orbit
git checkout -b add-notionUtils    # optional feature branch
git add modules/env/45-projects.zsh
git commit -m "orbit: add notionUtils to ORBIT_PROJECTS"
git push -u origin HEAD

# Fast-forward main (if you prefer to merge immediately)
git checkout main
git pull --ff-only
git merge --no-ff add-notionUtils -m "Merge branch 'add-notionUtils' into main"
git push
```

After this lands on `main`, any machine that starts a new shell (and thus runs the Orbit bootstrap in `.zshrc`) will fast‑forward and pick up the new helper.

---

## Activate and test

Use the package helper or `pkg`:

```bash
# Via the generated helper:
notionUtils

# or the generic jump/activate:
pkg notionUtils
```

Sanity checks inside the env:

```bash
python -V
python -c "import sys; print(sys.executable)"
uvp                      # prints UV_PROJECT_ENVIRONMENT (Orbit helper)
```

If the project needs SideFX Python, do a one-time pin with `hou`:

```bash
# inside your project folder
hou use                  # uses latest Houdini found
# or pin a specific Houdini build:
hou use 21.0.440
```

`hou use` will recreate the env with the SideFX Python if needed and run `uv sync` so the environment is ready.

---

## Everyday workflow tips

- **Jump to a package**: `pkg <name>` or use your helper (`notionUtils`).
- **Define a quick alias for the session**:
  ```zsh
  mkpkg notionUtils --alias nu   # then just run: nu
  ```
- **Force a fresh dependency sync**:
  ```zsh
  uvensure     # Orbit helper: lock (if missing) then sync
  ```
- **Build/publish**:
  ```zsh
  uv build
  # optional publisher helper (if defined): publish_notionUtils
  ```

---

## Houdini & Nuke notes (quick)

- Detected flags: `ORBIT_HAS_HOUDINI`, `ORBIT_HOUDINI_VERSION`, `ORBIT_HAS_NUKE`, etc.
- `hou pkgshim` writes a dev package JSON that exposes your env’s `site-packages` to Houdini:
  ```bash
  hou pkgshim  # creates $HOUDINI_USER_PREF_DIR/packages/98_uv_site.json
  ```
- `nukeUtils -e` prepares `~/.nuke` and `NUKE_PATH` if your project has `plugins/`.

---

## Common gotchas

- **“Where’s my `.venv`?”** Orbit uses external envs by default (`~/.venvs/<name>`). Override per-project if you want an in-repo `.venv`.
- **Changed Python version?** If the interpreter changed (e.g., new Houdini), Orbit’s activator will recreate the env automatically on next activation.
- **On `nimbus`** or other hosts with `ORBIT_USE_CONDA=1`, the helper will activate a Conda env with the same name instead of uv.
- **New helper not found?** Re‑source Orbit or start a new shell:
  ```zsh
  source "$ORBIT_HOME/core/bootstrap.zsh"
  ```

---

## One‑shot template (copy/paste)

```bash
# 1) Make the project
packages
mkdir myNewPkg && cd $_
uv init

# 2) (optional) create the env right now
uv venv && uv sync

# 3) Add to Orbit’s list
$EDITOR "$ORBIT_HOME/modules/env/45-projects.zsh"   # add: myNewPkg

# 4) Reload Orbit & test
source "$ORBIT_HOME/core/bootstrap.zsh"
myNewPkg   # or: pkg myNewPkg

# 5) Push Orbit update for other machines
orbit
git checkout -b add-myNewPkg
git add modules/env/45-projects.zsh
git commit -m "orbit: add myNewPkg to ORBIT_PROJECTS"
git push -u origin HEAD
git checkout main && git pull --ff-only && git merge --no-ff add-myNewPkg -m "Merge branch 'add-myNewPkg' into main" && git push
```
