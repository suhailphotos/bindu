y() {
  local tmp newcwd
  tmp="$(mktemp -t 'yazi-cwd.XXXXXX')" || return
  yazi --cwd-file="$tmp" "$@"
  if [[ -r "$tmp" ]]; then
    newcwd="$(cat -- "$tmp")"
    [[ -n "$newcwd" && "$newcwd" != "$PWD" ]] && cd -- "$newcwd"
    rm -f -- "$tmp"
  fi
}
alias yy='yazi'
alias yya='yazi --chooser=append'
