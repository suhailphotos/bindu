# apogee: eza helpers (fish)
command -v eza >/dev/null 2>&1; or return

set -q APOGEE_LS_ICONS; or set -gx APOGEE_LS_ICONS 0
set -q APOGEE_DOTFILES_SGR; or set -gx APOGEE_DOTFILES_SGR 90
set -q EZA_CONFIG_DIR; or set -gx EZA_CONFIG_DIR "$HOME/.config/eza"

function __apogee_eza_common_flags
  set -l flags --group-directories-first
  if test "$APOGEE_LS_ICONS" = "1"
    set flags $flags --icons=auto
  end
  echo $flags
end

function __apogee_eza_with_colors --description "run eza with dotfile dimming without clobbering theme"
  set -l old "$EZA_COLORS"
  set -lx EZA_COLORS ".*=$APOGEE_DOTFILES_SGR"
  if test -n "$old"
    set -lx EZA_COLORS "$EZA_COLORS:$old"
  end
  eza $argv
end

function ls;   __apogee_eza_with_colors (__apogee_eza_common_flags) $argv; end
function la;   __apogee_eza_with_colors -la (__apogee_eza_common_flags) $argv; end
function ll;   __apogee_eza_with_colors -lah (__apogee_eza_common_flags) $argv; end
function tree; __apogee_eza_with_colors --tree (__apogee_eza_common_flags) $argv; end
