# nukeUtils: activate & launch helper for your $PACKAGES/nukeUtils project

_nukeutils_root() {
  # Prefer PACKAGES from dropbox module
  if [ -n "${PACKAGES:-}" ] && [ -d "$PACKAGES/nukeUtils" ]; then
    printf '%s\n' "$PACKAGES/nukeUtils"
    return 0
  fi

  # Next: DROPBOX/matrix/packages
  if [ -n "${DROPBOX:-}" ] && [ -d "$DROPBOX/matrix/packages/nukeUtils" ]; then
    printf '%s\n' "$DROPBOX/matrix/packages/nukeUtils"
    return 0
  fi

  # Fallback common locations
  if [ -d "$HOME/Dropbox/matrix/packages/nukeUtils" ]; then
    printf '%s\n' "$HOME/Dropbox/matrix/packages/nukeUtils"
    return 0
  fi
  if [ -d "$HOME/Library/CloudStorage/Dropbox/matrix/packages/nukeUtils" ]; then
    printf '%s\n' "$HOME/Library/CloudStorage/Dropbox/matrix/packages/nukeUtils"
    return 0
  fi

  return 1
}

_nukeutils_prepend_pathvar() {
  # $1=varname $2=entry $3=sep
  var="$1"; entry="$2"; sep="$3"
  eval "cur=\${$var:-}"
  case "$sep$cur$sep" in
    *"$sep$entry$sep"*) return 0 ;;
  esac
  if [ -n "$cur" ]; then
    eval "export $var=\"$entry$sep$cur\""
  else
    eval "export $var=\"$entry\""
  fi
}

_nukeutils_launch() {
  # Prefer CLI if available
  if command -v nuke >/dev/null 2>&1; then
    nuke "$@"
    return $?
  fi

  # macOS app launch fallback: prefer Apogee's detected .app path
  if command -v open >/dev/null 2>&1; then
    if [ -n "${APOGEE_NUKE_DETECT_PATH:-}" ] && [ -d "${APOGEE_NUKE_DETECT_PATH:-}" ]; then
      open -a "$APOGEE_NUKE_DETECT_PATH" --args "$@" 2>/dev/null \
        || open -a "$APOGEE_NUKE_DETECT_PATH" 2>/dev/null \
        || { echo "Could not launch Nuke app: $APOGEE_NUKE_DETECT_PATH" >&2; return 1; }
      return 0
    fi

    # Best-effort fallback: by name only (no version guessing)
    edition="${NUKE_EDITION:-Nuke}" # Nuke | NukeX | NukeStudio
    open -a "$edition" --args "$@" 2>/dev/null \
      || open -a "$edition" 2>/dev/null \
      || { echo "Could not launch Nuke app: $edition (and no APOGEE_NUKE_DETECT_PATH)" >&2; return 1; }
    return 0
  fi

  echo "No 'nuke' command found and no macOS 'open' available." >&2
  return 1
}

nukeUtils() {
  cmd="${1:-}"; shift || true

  # If you ever call this without the module active, keep it harmless.
  if [ "${APOGEE_HAS_NUKE:-0}" != "1" ] && ! command -v nuke >/dev/null 2>&1; then
    return 1
  fi

  root="$(_nukeutils_root)" || {
    echo "nukeUtils project not found. Expected PACKAGES/nukeUtils (or Dropbox fallback)." >&2
    return 1
  }

  _nuke_activate() {
    [ -d "$root" ] || { echo "Project not found: $root" >&2; return 1; }
    [ "$PWD" = "$root" ] || cd "$root" || return 1

    # Optional: integrate with your uv helper if present
    if command -v _uv_activate_in_project >/dev/null 2>&1; then
      _uv_activate_in_project "$root" || return 1
    fi
  }

  _nuke_prefs_and_paths() {
    export NUKE_USER_DIR="${NUKE_USER_DIR:-$HOME/.nuke}"
    mkdir -p "$NUKE_USER_DIR" 2>/dev/null || true

    plugins="$root/plugins"
    if [ -d "$plugins" ]; then
      # NUKE_PATH separator differs on Windows; on posix keep ":"
      _nukeutils_prepend_pathvar "NUKE_PATH" "$plugins" ":"
    fi
  }

  case "$cmd" in
    -e|env)
      _nuke_activate || return 1
      _nuke_prefs_and_paths
      echo "Nuke env ready. root=$root"
      ;;
    launch|"")
      # default action: prepare env then launch
      _nuke_activate >/dev/null 2>&1 || true
      _nuke_prefs_and_paths
      _nukeutils_launch "$@"
      ;;
    *)
      echo "Usage: nukeUtils [launch] | nukeUtils -e" >&2
      return 1
      ;;
  esac
}
