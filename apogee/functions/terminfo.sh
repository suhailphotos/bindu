# Push current TERM’s entry to a remote host: push_terminfo user@host [TERM]
push_terminfo() {
  host="${1:-}"; shift || true
  term="${1:-${TERM:-xterm-256color}}"

  if [ -z "$host" ]; then
    echo "Usage: push_terminfo user@host [TERM]" >&2
    return 1
  fi

  if ! command -v infocmp >/dev/null 2>&1; then
    echo "push_terminfo: infocmp not found" >&2
    return 1
  fi
  if ! command -v tic >/dev/null 2>&1; then
    echo "push_terminfo: tic not found (install ncurses/terminfo tools on the remote)" >&2
    return 1
  fi
  if ! command -v ssh >/dev/null 2>&1; then
    echo "push_terminfo: ssh not found" >&2
    return 1
  fi

  if ! infocmp -x "$term" >/dev/null 2>&1; then
    echo "Local system doesn’t know term '$term'." >&2
    return 1
  fi

  infocmp -x "$term" | ssh "$host" 'mkdir -p ~/.terminfo && tic -x -o ~/.terminfo /dev/stdin'
}

# Quick check on a host: terminfo_ok user@host [TERM]
terminfo_ok() {
  host="${1:-}"; shift || true
  term="${1:-${TERM:-xterm-256color}}"

  if [ -z "$host" ]; then
    echo "Usage: terminfo_ok user@host [TERM]" >&2
    return 1
  fi

  ssh "$host" "infocmp -x $term >/dev/null 2>&1 && echo '$term: OK' || echo '$term: MISSING'"
}
