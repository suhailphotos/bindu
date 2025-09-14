# Brewhouse (Homebrew housekeeping & migration notes)

A tidy runbook for keeping Homebrew clean **and** migrating CLI tools you now manage with **Pixi**. It also documents how we investigated and silenced a `brew doctor` warning about an “unbrewed dylib”.

> TL;DR order of operations when housekeeping:
>
> 1. `brew update`
> 2. `brew upgrade`  (optional, but recommended before you judge “what’s unused”)
> 3. Remove any tools that are now managed by **Pixi**
> 4. `brew autoremove`  (drop orphans)
> 5. `brew cleanup -s`  (prune old versions & caches)
> 6. `brew doctor`  (read-only; investigate if anything looks scary)

---

## 0) Update & upgrade first

```zsh
brew update          # refresh metadata/taps
brew upgrade         # upgrade everything you still keep under Homebrew
# (Optional) Casks & greedy upgrades:
# brew upgrade --cask
# brew upgrade --greedy
```

Why first? Upgrading before removal makes it easier for Homebrew to correctly compute what’s actually an orphan later.

---

## 1) Identify packages to remove from Homebrew (because Pixi manages them)

Common overlap (your Pixi *global* manifest): `ffmpeg`, `imagemagick`, `poppler`, `p7zip`, `openimageio`, `libvips`, etc.

### Quick manual approach

- Show what Pixi exposes (from the active per‑host manifest):
  ```zsh
  pixi global list
  ```
- List Homebrew formulae:
  ```zsh
  brew list --formula | sort
  ```
- Intersect mentally (or use the Zsh helper below) and decide which to uninstall from Homebrew.

### Zsh helper to print overlap (run with Zsh)

```zsh
# Save as ubrewpkgs.sh and run with:  /bin/zsh ubrewpkgs.sh
manifest="$HOME/.pixi/manifests/pixi-global.toml"

# parse [envs.*] names from the manifest
pixi_envs=("${(f)$(grep -E '^\[envs\.' "$manifest" \
  | sed -E 's/^\[envs\.([^]]+)\].*/\1/' | sort -u)}")

# small name map (Homebrew names differ occasionally)
pixi_envs=(${(@)pixi_envs/#libvips/vips})

brew_formulae=("${(f)$(brew list --formula 2>/dev/null | sort)}")

# compute overlap
typeset -a overlap; overlap=()
for p in $pixi_envs; do
  if [[ " $brew_formulae " == *" $p "* ]]; then
    overlap+=("$p")
  fi
done

print -r -- "Pixi envs (from manifest): ${pixi_envs[*]}"
print -r -- "Overlap (installed by Homebrew AND declared in Pixi): ${overlap[*]}"
print -r -- "\nHomebrew dependents (if any):"
for p in $overlap; do
  deps=("${(f)$(brew uses --installed "$p" 2>/dev/null)}")
  if (( ${#deps} )); then
    printf "  %-15s -> %s\n" "$p" "${(j:, :)deps}"
  else
    printf "  %-15s -> (none)\n" "$p"
  fi
done
```

**Example output (from my run):**
```
Pixi envs (from manifest): ffmpeg imagemagick libvips openimageio p7zip poppler
Overlap (installed by Homebrew AND declared in Pixi): ffmpeg imagemagick poppler

Homebrew dependents (if any):
  ffmpeg          -> (none)
  imagemagick     -> (none)
  poppler         -> (none)
```

---

## 2) Uninstall the overlapped Homebrew packages

Example (from the overlap above):

```zsh
brew uninstall ffmpeg imagemagick poppler
```

This will also trigger **autoremove**‑like behavior for their now‑unused dependencies, or you can be explicit in the next step.

**Sanity check that you’re now using Pixi’s shims:**

```zsh
which -a ffmpeg
# /Users/<you>/.pixi/bin/ffmpeg

which -a convert
# /Users/<you>/.pixi/bin/convert

which -a pdftotext
# /Users/<you>/.pixi/bin/pdftotext

ffmpeg -version | head -n1
# ffmpeg version 8.0 Copyright (c) 2000-2025 the FFmpeg developers

convert -version | head -n1
# WARNING: The convert command is deprecated in IMv7, use "magick" instead of "convert" or "magick convert"
# Version: ImageMagick 7.1.2-3 Q16-HDRI aarch64 ...

pdftotext -v | head -n1
# pdftotext version 25.07.0
```

---

## 3) Autoremove & cleanup (and why those “Skipping … not installed” lines show up)

After removals:

```zsh
brew autoremove       # remove orphaned dependencies
brew cleanup -s       # prune old versions & scrub caches
```

It’s normal to see many lines like:

```
Warning: Skipping <formula>: most recent version X.Y.Z not installed
```

This means Homebrew found cache/metadata for a formula that isn’t currently installed at its latest version (or at all); cleanup just skips removing *current* artifacts it doesn’t manage. The important bit is the “Removing: …” lines and the final freed space summary.

---

## 4) `brew doctor` & investigating warnings

Run:

```zsh
brew doctor
```

### Case study: “**Unbrewed dylibs were found in /usr/local/lib**”

Homebrew complained about `/usr/local/lib/libASAF.dylib`. Here’s the full investigation we did (copy/paste to reproduce):

```zsh
# Inspect size/owner/flags/xattrs
ls -lO@ /usr/local/lib/libASAF.dylib

# What kind of binary?
file /usr/local/lib/libASAF.dylib

# Install name & linked libraries
otool -D /usr/local/lib/libASAF.dylib
otool -L /usr/local/lib/libASAF.dylib | sed 1d

# Code signature metadata
codesign -dv --verbose=4 /usr/local/lib/libASAF.dylib 2>&1 | sed -n '1,12p'

# Quick string sniff (optional curiosity)
strings -n 8 /usr/local/lib/libASAF.dylib | head -n 30

# Any process currently using it?
sudo lsof -n | grep -F '/usr/local/lib/libASAF.dylib' || echo "No processes currently using it."

# Where did it come from? (pkg receipts)
pkgutil --file-info /usr/local/lib/libASAF.dylib
pkgutil --pkg-info "com.Apple.pkg.ASAF.SDK"
pkgutil --files "com.Apple.pkg.ASAF.SDK" | sed -n '1,20p'
```

**What we found (summarized):**

- The dylib is from Apple’s **Audio Spatialization/Authoring SDK** (package id `com.Apple.pkg.ASAF.SDK`).
- The package also installed AU components under `/Library/Audio/Plug-Ins/Components/…`.
- Homebrew warns only because `/usr/local/lib` isn’t its prefix on Apple Silicon and the file wasn’t installed by Homebrew.

**Options:**

1) **Ignore** (safe): it’s Apple‑signed and harmless.
2) **Silence the warning, keep the SDK:** move only the dylib out of `/usr/local/lib`.
   ```zsh
   sudo mkdir -p /usr/local/lib/.quarantine
   sudo mv /usr/local/lib/libASAF.dylib /usr/local/lib/.quarantine/
   brew doctor
   # restore if needed:
   # sudo mv /usr/local/lib/.quarantine/libASAF.dylib /usr/local/lib/
   ```
3) **Remove/disable the SDK entirely:**
   ```zsh
   # Quarantine Audio Units
   sudo mkdir -p "/Library/Audio/Plug-Ins/Components/.quarantine"
   sudo mv "/Library/Audio/Plug-Ins/Components/ASAF Channels.component" \
           "/Library/Audio/Plug-Ins/Components/ASAF Channels Renderer.component" \
           "/Library/Audio/Plug-Ins/Components/.quarantine/"

   # Quarantine the dylib
   sudo mkdir -p /usr/local/lib/.quarantine
   sudo mv /usr/local/lib/libASAF.dylib /usr/local/lib/.quarantine/

   # (Optional) Forget the package receipt (removes only metadata)
   sudo pkgutil --forget com.Apple.pkg.ASAF.SDK
   ```

---

## 5) Final quick checks

```zsh
# Show PATH ordering (ensure ~/.pixi/bin is early)
echo "$PATH" | tr ':' '\n' | nl -ba

# Confirm active versions come from Pixi
which -a ffmpeg convert pdftotext

# Manifest sanity
pixi global list
```

**Example `pixi global list` (from my host):**
```
Global environments as specified in '/Users/suhail/.config/pixi/hosts/quasar/.pixi/manifests/pixi-global.toml'
├── ffmpeg: 8.0.0
│   └─ exposes: ffmpeg, ffplay, ffprobe
├── imagemagick: 7.1.2_3
│   └─ exposes: Magick++-config, MagickCore-config, MagickWand-config, animate, compare, composite, conjure, convert, display, identify, import, magick, magick-script, mogrify, montage, stream
├── libvips: 8.17.2
│   └─ exposes: vips, vipsedit, vipsheader, vipsthumbnail
├── openimageio: 2.5.18.0
│   └─ exposes: Nothing
├── p7zip: 16.02
│   └─ exposes: 7z, 7za, 7zr
└── poppler: 25.07.0
    └─ exposes: pdfattach, pdfdetach, pdffonts, pdfimages, pdfinfo, pdfseparate, pdfsig, pdftocairo, pdftohtml, pdftoppm, pdftops, pdftotext, pdfunite
```

---

## 6) One‑shot “regular housekeeping” block

When you just want to refresh and tidy everything quickly:

```zsh
brew update && brew upgrade && brew autoremove && brew cleanup -s && brew doctor
```

Scan the `brew doctor` output; if it’s only the ASAF dylib case above and you’ve quarantined it, you’re golden.

---

### Appendix: Why `brew cleanup -s` showed “Skipping … not installed”

Those lines are informational: Homebrew sees cache entries or metadata for formulae where the *latest* isn’t (or was never) installed locally, so it skips removing nonexistent “current” artifacts. The important part is the **Removing:** lines and the **freed space** summary.
