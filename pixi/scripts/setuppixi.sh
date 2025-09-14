# 0) run this with bash (or zsh). If you save as a script, use the shebang shown.
cat >/tmp/setup_pixi_hosts.sh <<'BASH'
#!/usr/bin/env bash
set -euo pipefail

HOSTS=(quasar feather eclipse nimbus flicker nexus)
BASE="$HOME/.config/pixi/hosts"

mkdir -p "$BASE"

for h in "${HOSTS[@]}"; do
  install -d "$BASE/$h/.pixi/manifests"
  cat >"$BASE/$h/.stow-local-ignore" <<'EOF'
^README\.md$
^notes/?$
^\.gitkeep$
EOF
done
BASH

chmod +x /tmp/setup_pixi_hosts.sh
/tmp/setup_pixi_hosts.sh
