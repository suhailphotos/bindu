# Only override when root (macOS/Linux pwsh)
if ($IsLinux -or $IsMacOS) {
  try {
    if ((id -u) -eq 0) {
      $env:STARSHIP_CONFIG = "$env:XDG_CONFIG_HOME/starship/starship_root.toml"
    }
  } catch { }
}
