#!/usr/bin/env bash
# Seed per-host Pixi packages under ~/.config/pixi/hosts
# - Creates hosts/<host>/.pixi/manifests
# - Populates each with a manifest from live ~/.pixi/manifests/pixi-global.toml,
#   else from ~/.pixi.bak/pixi-global.toml, else a minimal ffmpeg-only manifest
# - Writes per-host .stow-local-ignore (includes .DS_Store)

set -euo pipefail

HOSTS=(quasar feather eclipse nimbus flicker nexus)
BASE="$HOME/.config/pixi/hosts"

mkdir -p "$BASE"

# Choose a seed manifest if present
SEED=""
for candidate in "$HOME/.pixi/manifests/pixi-global.toml" "$HOME/.pixi.bak/pixi-global.toml"; do
  if [ -f "$candidate" ]; then
    SEED="$candidate"
    break
  fi
done

# Minimal manifest if no seed found
read -r -d '' MINIMAL <<'EOF' || true
version = 1

[envs.ffmpeg]
channels = ["conda-forge"]
dependencies = { ffmpeg = "*" }
exposed = { ffmpeg = "ffmpeg", ffplay = "ffplay", ffprobe = "ffprobe" }
EOF

for h in "${HOSTS[@]}"; do
  install -d "$BASE/$h/.pixi/manifests"

  # Ignore junk for Stow
  cat >"$BASE/$h/.stow-local-ignore" <<'EOF'
^README\.md$
^notes/?$
^\.gitkeep$
^\.DS_Store$
EOF

  # Populate manifest
  if [ -n "${SEED:-}" ]; then
    cp -f "$SEED" "$BASE/$h/.pixi/manifests/pixi-global.toml"
  else
    printf "%s\n" "$MINIMAL" >"$BASE/$h/.pixi/manifests/pixi-global.toml"
  fi
done

# Ensure the local target parent exists on THIS machine for Stow to place the symlink
install -d "$HOME/.pixi/manifests"

echo "Seeded hosts at: $BASE"
echo "Next on each host:"
echo "  stow -d \"$BASE\" -t \"$HOME\" -R \"\$(hostname -s)\""
echo "  pixi global list"
