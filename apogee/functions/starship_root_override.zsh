# Only override when root
if command -v id >/dev/null 2>&1 && [[ "$(id -u)" == "0" ]]; then
  export STARSHIP_CONFIG="$XDG_CONFIG_HOME/starship/starship_root.toml"
fi
