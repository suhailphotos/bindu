# Only override when root
if type -q id
  if test (id -u) -eq 0
    set -gx STARSHIP_CONFIG "$XDG_CONFIG_HOME/starship/starship_root.toml"
  end
end
