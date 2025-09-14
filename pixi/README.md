# Pixi (global) per‑host manifests with GNU Stow

This layout makes **Pixi’s global tool installs** reproducible and host‑specific, while keeping everything version‑controlled in **Bindu**.

You keep **one tiny Stow package per host** that contains only a single file:
`~/.pixi/manifests/pixi-global.toml`. Each machine symlinks its own copy into place.

---

## Why this layout?

- **Reproducible** – the exact global tools each host has are captured in a single manifest file.
- **Host‑specific** – every host gets its own manifest (`hosts/<host>/.pixi/manifests/pixi-global.toml`). No conditionals.
- **Safe** – we link **only** the manifest. Pixi’s generated binaries/envs stay under `~/.pixi/{bin,envs}` and are **not** tracked.
- **Simple diffs** – changes via `pixi global install/remove …` become a single TOML change per host.
- **Easy add/remove hosts** with Stow packages.

---

## Directory layout (in Bindu)

```
~/.config/pixi/
  README.md                 # this file
  hosts/
    <host>/                 # one Stow package per host
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

> Example uses **eclipse**. Replace with `$(hostname -s)` if you prefer.

1) **Install Pixi** without touching your shell rc (Orbit manages `$PATH`):

```bash
curl -fsSL https://pixi.sh/install.sh | env PIXI_NO_PATH_UPDATE=1 zsh
```

If needed, add a one‑off PATH:
```bash
export PATH="$HOME/.pixi/bin:$PATH"
```

2) **Pull Bindu** so you have this layout under `~/.config/pixi`.

3) **Ensure the target parent exists** (required for Stow to place the symlink):
```bash
mkdir -p "$HOME/.pixi/manifests"
```

4) **Activate the per‑host manifest via Stow**:
```bash
stow -d "$HOME/.config/pixi/hosts" -t "$HOME" -R "eclipse"
# or: stow -d "$HOME/.config/pixi/hosts" -t "$HOME" -R "$(hostname -s)"
```

5) **Verify and apply tools**:
```bash
ls -l "$HOME/.pixi/manifests/pixi-global.toml"
pixi global list

# First time on a fresh box, apply your baseline:
pixi global install -c conda-forge ffmpeg imagemagick poppler p7zip openimageio libvips
# (macOS: add pngpaste; Linux: xclip wl-clipboard)
```

---

## Daily workflow

- **Add a tool** (updates this host’s manifest):
  ```bash
  pixi global install -c conda-forge <package>
  git -C ~/.config add "pixi/hosts/$(hostname -s)/.pixi/manifests/pixi-global.toml"
  git -C ~/.config commit -m "pixi($(hostname -s)): add <package>"
  git -C ~/.config push
  ```

- **Remove a tool**:
  ```bash
  pixi global remove <package>
  git -C ~/.config add "pixi/hosts/$(hostname -s)/.pixi/manifests/pixi-global.toml"
  git -C ~/.config commit -m "pixi($(hostname -s)): remove <package>"
  git -C ~/.config push
  ```

- **Inspect**:
  ```bash
  pixi global list
  ```

---

## Seeding manifests for multiple hosts (one‑time)

From a machine that already has a good `~/.pixi/manifests/pixi-global.toml` (or a backup):

```bash
bash seed_pixi_hosts.sh
git -C ~/.config add pixi/hosts
git -C ~/.config commit -m "seed Pixi per-host manifests"
git -C ~/.config push
```

What the script does:
- Creates `~/.config/pixi/hosts/<host>/.pixi/manifests/` for each host.
- Populates each with a manifest, **preferring** your live `~/.pixi/manifests/pixi-global.toml`,
  falling back to `~/.pixi.bak/pixi-global.toml`, else a minimal `ffmpeg`‑only manifest.
- Writes a per‑host `.stow-local-ignore` (includes `.DS_Store`).

Then, on **each host**:
```bash
# make sure the symlink’s parent exists on this box
mkdir -p "$HOME/.pixi/manifests"

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
curl -fsSL https://pixi.sh/install.sh | env PIXI_NO_PATH_UPDATE=1 zsh
mkdir -p "$HOME/.pixi/manifests"
stow -d "$HOME/.config/pixi/hosts" -t "$HOME" -R "$(hostname -s)"
pixi global install -c conda-forge ffmpeg imagemagick poppler p7zip openimageio libvips  # if fresh
```

---

## Removing a host cleanly

On the departing host (or managing from another machine):

```bash
# 1) Unlink its package locally (on the host itself)
stow -d "$HOME/.config/pixi/hosts" -t "$HOME" -D "$(hostname -s)"

# 2) Remove the package from the repo
git -C ~/.config rm -r "pixi/hosts/<host>"
git -C ~/.config commit -m "pixi: drop host <host>"
git -C ~/.config push
```

> Note: This does **not** delete tool envs in `~/.pixi/envs`. Remove specific tools with
> `pixi global remove <pkg>` (recommended) or manually clean env dirs if needed.

---

## Base package suggestions

Common cross‑platform set:
```text
ffmpeg, imagemagick, poppler, p7zip, openimageio, libvips
# macOS only: pngpaste
# Linux only: xclip, wl-clipboard
```

Always prefer the channel:
```bash
pixi global install -c conda-forge <packages...>
```

---

## Troubleshooting

- **Dry‑run Stow**:
  ```bash
  stow -n -v -d "$HOME/.config/pixi/hosts" -t "$HOME" "$(hostname -s)"
  ```

- **Wrong host linked?**
  ```bash
  stow -d "$HOME/.config/pixi/hosts" -t "$HOME" -D wronghost
  stow -d "$HOME/.config/pixi/hosts" -t "$HOME" -R righthost
  ```

- **Confirm which manifest is active**:
  ```bash
  readlink "$HOME/.pixi/manifests/pixi-global.toml"
  pixi global list
  ```

- **Name not found**:
  Use conda‑forge names: `p7zip` (not `7zip`), `libvips` (not `vips`).
