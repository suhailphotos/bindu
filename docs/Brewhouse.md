# Brewhouse — Homebrew housekeeping & de‑dup with Pixi

This doc captures a clean, repeatable flow for managing your Homebrew
installs, especially now that **Pixi** owns some of your CLI tools.

---

## TL;DR routines

### A) Remove tools that Pixi now manages (one‑off per host)

If you’ve moved `ffmpeg`, `imagemagick`, `poppler`, etc. to Pixi:

```bash
# 1) Uninstall just those formulae
brew uninstall ffmpeg imagemagick poppler

# 2) Drop now‑unneeded dependency leafs
brew autoremove

# 3) Vacuum old versions and caches (aggressive)
brew cleanup -s

# 4) Sanity check
brew doctor
which -a ffmpeg convert pdftotext
```

> Why this order? Uninstalling first makes `autoremove` smarter (it only
> removes dependencies that are no longer needed). `cleanup -s` then clears
> the old versions and cache files left behind.

---

### B) Regular housekeeping (monthly-ish)

```bash
# Refresh metadata
brew update

# (Optional) Upgrade all or just a few critical ones
brew upgrade                # or: brew upgrade <name> <name> ...

# Trim unused deps
brew autoremove

# Delete old versions & caches
brew cleanup -s

# Quick health check
brew doctor
```

> If you don’t plan to upgrade soon, you can still run `autoremove` and
> `cleanup -s` to reclaim space safely.

---

## Commands explained

- **`brew uninstall <formula…>`**  
  Removes specified formulae only. It doesn’t touch dependencies that are still required by something else.

- **`brew autoremove`**  
  Removes **leaf** dependencies that were installed automatically by Homebrew and are no longer needed by any installed formula.

- **`brew cleanup -s`**  
  Deletes old versions of currently‑installed formulae and aggressively purges caches
  (the `-s` flag removes downloads from `~/Library/Caches/Homebrew`).

- **`brew update`**  
  Updates the local metadata for the Homebrew core and taps (no package changes yet).

- **`brew upgrade [formula…]`**  
  Upgrades installed formulae to the latest versions. Use without args to upgrade
  everything, or pass names to upgrade selectively.

- **`brew doctor`**  
  Prints diagnostics that are often safe to ignore but useful when something breaks.

---

## Warnings you may see (and what they mean)

- **`Warning: Skipping <name>: most recent version <X> not installed`** (from `brew cleanup`)  
  You have an **older** version of `<name>` still installed. `cleanup` won’t delete it
  because it’s your active version. Options:
  - Upgrade it: `brew upgrade <name>`; then re‑run `brew cleanup -s`  
  - Or remove it entirely if Pixi owns it now: `brew uninstall <name>`  
  - Or you’ve **pinned** it on purpose—check with `brew pinned` and `brew unpin <name>` if needed.

- **`Warning: Unbrewed dylibs were found in /usr/local/lib`** (from `brew doctor`)  
  Files not managed by Homebrew live in `/usr/local/lib`. If you didn’t put them there
  on purpose, consider removing them after verifying nothing depends on them:
  ```bash
  ls -l /usr/local/lib/libASAF.dylib
  # If you’re sure it’s safe:
  sudo rm -f /usr/local/lib/libASAF.dylib
  ```
  (Most Apple‑Silicon Homebrew installs under `/opt/homebrew`; `/usr/local` is typically
  legacy Intel paths or 3rd‑party installers.)

- **`Skipping <name> (not installed)`**  
  You asked `brew` to operate on something that isn’t currently installed with Homebrew.

---

## De‑duping with Pixi (sanity checks)

Confirm that **Pixi’s** shims are first on `PATH` and the tools resolve to Pixi:

```bash
which -a ffmpeg convert pdftotext
# Expect: /Users/<you>/.pixi/bin/ffmpeg ... etc.

ffmpeg -version | head -n1
convert -version | head -n1    # or: magick -version
pdftotext -v | head -n1
```

If a Homebrew copy still comes first, fix PATH (Orbit ensures `~/.pixi/bin` is
prepended) or remove the Homebrew formula.

---

## Nice‑to‑have queries

```bash
brew list --formula           # show currently installed formulae
brew list --cask              # show installed casks
brew info --installed         # detailed table with versions
brew uses --installed <name>  # who depends on <name>
brew leaves                   # leaf formulae (nothing depends on them)
brew outdated                 # what would upgrade
brew pinned                   # what’s held back
```

---

## Tips

- Avoid `sudo` with Homebrew (except to remove stray files under `/usr/local` you put there yourself).
- Keep Pixi‑owned tools off Homebrew to avoid duplicates (`which -a` is your friend).
- If you routinely build from source or use custom taps, run `brew update` more often.
- Casks are independent: you can `brew upgrade --cask --greedy` periodically to bump apps.
