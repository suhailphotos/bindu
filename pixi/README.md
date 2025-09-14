# Pixi (global) per‑host manifests with GNU Stow

This repo layout makes **Pixi’s global tool installs** reproducible and host‑specific, while keeping everything version‑controlled in **Bindu**.

You’ll keep **one tiny Stow package per host** that contains only a single file:
`~/.pixi/manifests/pixi-global.toml`. Each machine symlinks its own copy into place.

---

## Why this layout?

- **Reproducible**: The exact global tools each host has are captured in a single manifest file.
- **Host‑specific**: Every host gets its own manifest (`hosts/<host>/.pixi/manifests/pixi-global.toml`). No conditionals.
- **Safe**: We link **only** the manifest. Pixi’s generated binaries and envs remain under `~/.pixi/{bin,envs}` and are **not** tracked by git.
- **Simple diffs**: Changes you make with `pixi global install/remove …` are just a single TOML change per host.
- **Easy to add/remove hosts** with Stow.

---

## Directory layout (in Bindu)

```
~/.config/pixi/
  README.md                 # this file
  hosts/
    <host>/                 # one package per host
      .pixi/
        manifests/
          pixi-global.toml  # the only tracked file per host
```

On each machine you run Stow against **its own host folder** so that:
```
~/.pixi/manifests/pixi-global.toml -> ~/.config/pixi/hosts/<host>/.pixi/manifests/pixi-global.toml
```

---

## Quick start (new machine)

> Example below uses **eclipse** as the host. Replace with `$(hostname -s)` if you like.

1) **Install Pixi** without touching your shell rc (Orbit manages `$PATH`):
```bash
PIXI_NO_PATH_UPDATE=1 curl -fsSL https://pixi.sh/install.sh | zsh
```
Orbit (or your shell) must put `~/.pixi/bin` on PATH. A one‑off fallback is:
```bash
export PATH="$HOME/.pixi/bin:$PATH"
```

2) **Pull Bindu** (so you have this layout under `~/.config/pixi`).

3) **Activate the per‑host manifest via Stow**:
```bash
stow -d "$HOME/.config/pixi/hosts" -t "$HOME" -R "eclipse"
# or: stow -d "$HOME/.config/pixi/hosts" -t "$HOME" -R "$(hostname -s)"
```

4) **Verify the link**:
```bash
ls -l "$HOME/.pixi/manifests/pixi-global.toml"
# ~/.pixi/manifests/pixi-global.toml -> ../../.config/pixi/hosts/eclipse/.pixi/manifests/pixi-global.toml
```

5) **Bring tools up to date** (reads the manifest you just linked):
```bash
pixi global list
# sanity check what’s declared

# (Optional) Re-apply to ensure local matches the manifest
# e.g., if you just seeded the manifest on a fresh machine:
pixi global install -c conda-forge ffmpeg imagemagick poppler p7zip openimageio libvips
```

> Tip: On macOS, `pngpaste` is nice to add; on Linux, `xclip` / `wl-clipboard` are handy.
> Because this is per‑host, just add them on the relevant machines.

---

## Daily workflow

- **Add a tool** (updates the current host’s manifest):
  ```bash
  pixi global install -c conda-forge <package>
  git -C ~/.config add "pixi/hosts/$(hostname -s)/.pixi/manifests/pixi-global.toml"
  git -C ~/.config commit -m "pixi(<host>): add <package>"
  git -C ~/.config push
  ```

- **Remove a tool**:
  ```bash
  pixi global remove <package>
  git -C ~/.config add "pixi/hosts/$(hostname -s)/.pixi/manifests/pixi-global.toml"
  git -C ~/.config commit -m "pixi(<host>): remove <package>"
  git -C ~/.config push
  ```

- **Inspect what’s declared vs installed**:
  ```bash
  pixi global list
  ```

---

## Seeding manifests for multiple hosts (one‑time)

From a machine that already has a good `~/.pixi/manifests/pixi-global.toml`:

```bash
HOSTS=(quasar feather eclipse nimbus flicker nexus)

# ensure per-host package dirs exist
mkdir -p "$HOME/.config/pixi/hosts"
for h in "${HOSTS[@]}"; do
  mkdir -p "$HOME/.config/pixi/hosts/$h/.pixi/manifests"
done

# choose a seed manifest (prefer your live one; fall back to backup)
SEED="$HOME/.pixi/manifests/pixi-global.toml"
[ -f "$SEED" ] || SEED="$HOME/.pixi.bak/pixi-global.toml"

# copy the seed into each host’s package
for h in "${HOSTS[@]}"; do
  cp -f "$SEED" "$HOME/.config/pixi/hosts/$h/.pixi/manifests/pixi-global.toml"
done

# commit once
git -C ~/.config add pixi/hosts
git -C ~/.config commit -m "seed Pixi per-host manifests"
git -C ~/.config push
```

Then on each host:
```bash
stow -d "$HOME/.config/pixi/hosts" -t "$HOME" -R "$(hostname -s)"
pixi global list
```

---

## Adding a new host later

```bash
H=newhost
mkdir -p "$HOME/.config/pixi/hosts/$H/.pixi/manifests"
cp "$HOME/.config/pixi/hosts/quasar/.pixi/manifests/pixi-global.toml" \
   "$HOME/.config/pixi/hosts/$H/.pixi/manifests/pixi-global.toml"

git -C ~/.config add "pixi/hosts/$H"
git -C ~/.config commit -m "pixi: add host $H"
git -C ~/.config push
```

On that new machine:
```bash
PIXI_NO_PATH_UPDATE=1 curl -fsSL https://pixi.sh/install.sh | zsh
stow -d "$HOME/.config/pixi/hosts" -t "$HOME" -R "$(hostname -s)"
pixi global install -c conda-forge ffmpeg imagemagick poppler p7zip openimageio libvips  # if fresh
```

---

## Removing a host cleanly

On the departing host (or from any machine managing the repo):

```bash
# 1) Unlink its package locally (on the host itself)
stow -d "$HOME/.config/pixi/hosts" -t "$HOME" -D "$(hostname -s)"

# 2) Remove the package from the repo
git -C ~/.config rm -r "pixi/hosts/<host>"
git -C ~/.config commit -m "pixi: drop host <host>"
git -C ~/.config push
```

> Note: This does **not** delete already‑downloaded tool envs in `~/.pixi/envs`.
> If you want to reclaim space, you can remove those env dirs by hand or use Pixi
> commands (e.g., remove specific tools with `pixi global remove <pkg>` before unlinking).

---

## Base package suggestions

Common set that tends to work well cross‑platform:
```text
ffmpeg, imagemagick, poppler, p7zip, openimageio, libvips
# macOS only: pngpaste
# Linux only: xclip, wl-clipboard
```

Use `-c conda-forge` with `pixi global install` to ensure these resolve as expected:
```bash
pixi global install -c conda-forge ffmpeg imagemagick poppler p7zip openimageio libvips
```

---

## Troubleshooting

- **Stow dry‑run first**:
  ```bash
  stow -n -v -d "$HOME/.config/pixi/hosts" -t "$HOME" "$(hostname -s)"
  ```

- **Wrong host linked?** Unstow then restow the correct host:
  ```bash
  stow -d "$HOME/.config/pixi/hosts" -t "$HOME" -D wronghost
  stow -d "$HOME/.config/pixi/hosts" -t "$HOME" -R righthost
  ```

- **Confirm which manifest is active**:
  ```bash
  readlink "$HOME/.pixi/manifests/pixi-global.toml"
  pixi global list
  ```

- **Package name not found**:
  Always prefer `-c conda-forge`. Some names differ from OS package managers:
  - `p7zip` (not `7zip`)
  - `libvips` (not `vips`)

---

## Notes

- We intentionally **do not** track Pixi’s generated files (`~/.pixi/bin`, `~/.pixi/envs`). Only the manifest is in git.
- Because each host has a standalone package, you’re free to later add more files to a host’s package (e.g., host notes), and Stow will handle them too.
