# apogee: eza helpers (bash/zsh)
command -v eza >/dev/null 2>&1 || return

: "${APOGEE_LS_ICONS:=0}"
: "${APOGEE_DOTFILES_SGR:=90}"
: "${EZA_CONFIG_DIR:=$HOME/.config/eza}"

_apogee_eza_common_flags() {
  local flags="--group-directories-first"
  if [[ "${APOGEE_LS_ICONS}" == "1" ]]; then
    flags+=" --icons=auto"
  fi
  print -r -- "$flags"
}

_apogee_eza_colors_prefix() {
  local dotrule=".*=${APOGEE_DOTFILES_SGR}"
  if [[ -n "${EZA_COLORS:-}" ]]; then
    print -r -- "${dotrule}:${EZA_COLORS}"
  else
    print -r -- "${dotrule}"
  fi
}

# Use aliases (fast + simple) with per-invocation env override
alias ls="EZA_COLORS='$(_apogee_eza_colors_prefix)' eza $(_apogee_eza_common_flags)"
alias la="EZA_COLORS='$(_apogee_eza_colors_prefix)' eza -la $(_apogee_eza_common_flags)"
alias ll="EZA_COLORS='$(_apogee_eza_colors_prefix)' eza -lah $(_apogee_eza_common_flags)"
alias tree="EZA_COLORS='$(_apogee_eza_colors_prefix)' eza --tree $(_apogee_eza_common_flags)"
