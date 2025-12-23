_have() { command -v "$1" >/dev/null 2>&1; }

_clip_have_wayland() {
  [[ -n "${WAYLAND_DISPLAY-}" ]] || return 1
  local sock="${XDG_RUNTIME_DIR:-/run/user/$UID}/${WAYLAND_DISPLAY}"
  [[ -S "$sock" ]]
}
_clip_have_x11() { [[ -n "${DISPLAY-}" ]]; }

_osc52_copy() {
  local data
  data=$(base64 | tr -d '\r\n')
  if [[ -n "${TMUX-}" ]]; then
    printf '\ePtmux;\e]52;c;%s\a\e\\' "$data" > /dev/tty
  else
    printf '\e]52;c;%s\a' "$data" > /dev/tty
  fi
}

pbcopy() {
  if _have clip.exe; then cat | clip.exe; return $?; fi
  if _clip_have_wayland && _have wl-copy; then wl-copy; return $?; fi
  if _clip_have_x11 && _have xclip; then xclip -selection clipboard; return $?; fi
  if _clip_have_x11 && _have xsel; then xsel --clipboard --input; return $?; fi
  _osc52_copy
}

pbpaste() {
  if _clip_have_wayland && _have wl-paste; then wl-paste -n; return $?; fi
  if _clip_have_x11 && _have xclip; then xclip -selection clipboard -o; return $?; fi
  if _clip_have_x11 && _have xsel; then xsel --clipboard --output; return $?; fi
  if _have powershell.exe; then powershell.exe -NoProfile -Command 'Get-Clipboard' 2>/dev/null; return $?; fi
  echo "pbpaste: no clipboard program available" >&2
  return 1
}
