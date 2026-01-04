# apogee/functions/python_env.bash
# UV-first python env + pkg (bash)

: "${APOGEE_UV_VENV_ROOT:=$HOME/.venvs}"
: "${APOGEE_UV_DEFAULT_PY:=auto-houdini}"
: "${APOGEE_UV_QUIET:=0}"
: "${APOGEE_UV_SYNC_ON_ACTIVATE:=0}"
: "${APOGEE_UV_FORCE_SYNC:=0}"

_apogee_py_deactivate() {
  if command -v conda >/dev/null 2>&1 && [ "${CONDA_SHLVL:-0}" -gt 0 ]; then
    while [ "${CONDA_SHLVL:-0}" -gt 0 ]; do conda deactivate >/dev/null 2>&1 || break; done
  fi
  if [ -n "${VIRTUAL_ENV:-}" ] && command -v deactivate >/dev/null 2>&1; then
    deactivate >/dev/null 2>&1 || true
  fi
}

env_off() { _apogee_py_deactivate; }

_apogee_uv_project_root() {
  if command -v git >/dev/null 2>&1; then
    local root
    root="$(git -C . rev-parse --show-toplevel 2>/dev/null)" \
      && [ -f "$root/pyproject.toml" ] \
      && { echo "$root"; return 0; }
  fi

  local d="$PWD"
  while [ "$d" != "/" ]; do
    [ -f "$d/pyproject.toml" ] && { echo "$d"; return 0; }
    d="${d%/*}"
    [ -z "$d" ] && d="/"
  done
  return 1
}

_apogee_uv_env_for() {
  local root="$1"
  echo "${APOGEE_UV_VENV_ROOT}/$(basename "$root")"
}

_apogee_uv_set_envvar() {
  local root
  root="$(_apogee_uv_project_root)" || { unset UV_PROJECT_ENVIRONMENT; return 0; }
  export UV_PROJECT_ENVIRONMENT="$(_apogee_uv_env_for "$root")"
}

# prompt hook without clobbering user's PROMPT_COMMAND
_apogee_install_prompt_hook() {
  case ";${PROMPT_COMMAND:-};" in
    *";_apogee_uv_set_envvar;"*) ;;
    *) PROMPT_COMMAND="_apogee_uv_set_envvar; ${PROMPT_COMMAND:-}" ;;
  esac
}
_apogee_install_prompt_hook

uv() {
  _apogee_uv_set_envvar
  command uv "$@"
}

uvp() { printf '%s\n' "${UV_PROJECT_ENVIRONMENT:-(unset)}"; }

# --- Python selection helpers -------------------------------------------------

_apogee_py_mm_to_num() {
  # "3.11" -> 311  (simple compare)
  local mm="$1"
  local maj="${mm%%.*}"
  local min="${mm#*.}"
  printf '%d\n' "$((maj * 100 + min))"
}

_apogee_pyproject_requires_python() {
  # Extract requires-python = ">=3.11.0,<4.0.0"
  local root="$1"
  local f="$root/pyproject.toml"
  [ -f "$f" ] || return 1

  awk -F= '
    $1 ~ /^[[:space:]]*requires-python[[:space:]]*$/ {
      gsub(/^[[:space:]]+|[[:space:]]+$/,"",$2);
      gsub(/"/,"",$2);
      print $2;
      exit
    }
  ' "$f"
}

_apogee_requires_min_mm() {
  # From ">=3.11.0,<4.0.0" -> "3.11"
  local spec="$1"
  # find first >=X.Y
  if printf '%s' "$spec" | grep -Eq '>=\s*[0-9]+\.[0-9]+'; then
    printf '%s' "$spec" \
      | sed -nE 's/.*>=\s*([0-9]+)\.([0-9]+).*/\1.\2/p' \
      | head -n1
    return 0
  fi

  # fallback: any X.Y
  if printf '%s' "$spec" | grep -Eq '[0-9]+\.[0-9]+'; then
    printf '%s' "$spec" \
      | sed -nE 's/.*([0-9]+)\.([0-9]+).*/\1.\2/p' \
      | head -n1
    return 0
  fi
  return 1
}

_apogee_houdini_python_mm() {
  # Prefer hython if present; otherwise try detected path
  if command -v hython >/dev/null 2>&1; then
    hython -c 'import sys; print(f"{sys.version_info[0]}.{sys.version_info[1]}")' 2>/dev/null
    return $?
  fi

  if [ -n "${APOGEE_HOUDINI_DETECT_PATH:-}" ] && [ -x "${APOGEE_HOUDINI_DETECT_PATH}/bin/hython" ]; then
    "${APOGEE_HOUDINI_DETECT_PATH}/bin/hython" -c 'import sys; print(f"{sys.version_info[0]}.{sys.version_info[1]}")' 2>/dev/null
    return $?
  fi

  return 1
}

_apogee_uv_default_python_spec() {
  local mode="${APOGEE_UV_DEFAULT_PY:-auto-houdini}"
  if [ -n "$mode" ] && [ "$mode" != "auto-houdini" ]; then
    echo "$mode"
    return 0
  fi

  # auto-houdini: return Houdini major.minor if available
  local hou_mm=""
  hou_mm="$(_apogee_houdini_python_mm 2>/dev/null)" || true
  if [ -n "$hou_mm" ]; then
    echo "$hou_mm"
    return 0
  fi

  # fallback: system python3 if present, else "3"
  command -v python3 >/dev/null 2>&1 && command -v python3 || echo "3"
}

_apogee_uv_pick_python_for_project() {
  local root="$1"

  # 1) explicit .python-version wins (uv-native)
  if [ -f "$root/.python-version" ]; then
    # first token, trim whitespace/newlines
    tr -d '\r' < "$root/.python-version" | awk '{print $1; exit}'
    return 0
  fi

  # 2) derive from requires-python if present
  local req="" min_mm=""
  req="$(_apogee_pyproject_requires_python "$root" 2>/dev/null)" || true
  min_mm="$(_apogee_requires_min_mm "$req" 2>/dev/null)" || true

  # 3) auto-houdini default, but only if it satisfies min requirement (when known)
  local def="" def_mm=""
  def="$(_apogee_uv_default_python_spec)"
  def_mm="$def"

  if [ -n "$min_mm" ]; then
    # If default is a path (python3), just use min_mm
    if printf '%s' "$def" | grep -Eq '^[0-9]+\.[0-9]+$'; then
      if [ "$(_apogee_py_mm_to_num "$def_mm")" -ge "$(_apogee_py_mm_to_num "$min_mm")" ]; then
        echo "$def_mm"
        return 0
      fi
    fi
    echo "$min_mm"
    return 0
  fi

  # 4) nothing to infer -> default
  echo "$def"
}

_apogee_uv_pin_python_if_missing() {
  local root="$1" py="$2"

  # only pin numeric major.minor / major.minor.patch; don't pin paths like /usr/bin/python3
  printf '%s' "$py" | grep -Eq '^[0-9]+(\.[0-9]+){0,2}$' || return 0

  [ -f "$root/.python-version" ] && return 0
  [ -w "$root" ] || return 0

  # This creates .python-version (uv-native)
  command uv python pin "$py" >/dev/null 2>&1 || true
}

_apogee_uv_ensure_python_installed() {
  local py="$1"

  # Only install numeric specs; if it's a path or "python3", uv can try it directly.
  printf '%s' "$py" | grep -Eq '^[0-9]+(\.[0-9]+){0,2}$' || return 0

  command uv python install "$py" >/dev/null 2>&1 || return 1
}

# --- Activation ---------------------------------------------------------------

_apogee_uv_activate_in_project() {
  local root="$1"
  [ -d "$root" ] || { echo "Project not found: $root" >&2; return 1; }
  cd "$root" || return 1

  _apogee_py_deactivate
  command -v uv >/dev/null 2>&1 || { echo "uv not found on PATH" >&2; return 127; }

  local envroot="${UV_PROJECT_ENVIRONMENT:-${APOGEE_UV_VENV_ROOT}/$(basename "$root")}"
  export UV_PROJECT_ENVIRONMENT="$envroot"   # lets uv know where to put the env  [oai_citation:2‡Astral Docs](https://docs.astral.sh/uv/reference/environment/)

  local want_spec=""
  want_spec="$(_apogee_uv_pick_python_for_project "$root")"

  # If .python-version is missing, pin once so future runs are deterministic
  _apogee_uv_pin_python_if_missing "$root" "$want_spec"

  # Ensure the interpreter exists (persisted under UV_PYTHON_INSTALL_DIR if you set it)
  _apogee_uv_ensure_python_installed "$want_spec" || {
    echo "uv: failed to install/ensure Python '$want_spec'" >&2
    return 1
  }

  local q=""
  [ "${APOGEE_UV_QUIET:-0}" = "1" ] && q="-q"

  # Create env if missing
  if [ ! -x "$envroot/bin/python" ]; then
    rm -rf "$envroot" 2>/dev/null || true
    command uv venv --python "$want_spec" $q "$envroot" || return 1

    # Sync deps
    if [ -f uv.lock ]; then
      command uv sync --frozen $q || return 1
    else
      command uv lock $q && command uv sync $q || return 1
    fi
  else
    # Optional sync on activate
    if [ "${APOGEE_UV_SYNC_ON_ACTIVATE:-0}" = "1" ] || [ "${APOGEE_UV_FORCE_SYNC:-0}" = "1" ]; then
      if [ -f uv.lock ]; then
        command uv sync --frozen $q || return 1
      else
        command uv lock $q && command uv sync $q || return 1
      fi
    fi
  fi

  # Activate
  # shellcheck disable=SC1090
  . "$envroot/bin/activate"
}

# --- pkg ---------------------------------------------------------------------

_apogee_pkg_root() {
  if [ -n "${PACKAGES:-}" ]; then echo "$PACKAGES"; return 0; fi
  if [ -n "${MATRIX:-}" ]; then echo "$MATRIX/packages"; return 0; fi
  echo "$HOME/packages"
}

_apogee_pkg_resolve() {
  local arg="$1" root
  root="$(_apogee_pkg_root)"

  [ -d "$arg" ] && { cd "$arg" >/dev/null 2>&1 && pwd && return 0; }
  [ -d "$root/$arg" ] && { echo "$root/$arg"; return 0; }

  # case-insensitive scan
  local d
  for d in "$root"/*; do
    [ -d "$d" ] || continue
    [ "$(printf '%s' "$(basename "$d")" | tr '[:upper:]' '[:lower:]')" = "$(printf '%s' "$arg" | tr '[:upper:]' '[:lower:]')" ] \
      && { echo "$d"; return 0; }
  done
  return 1
}

pkg() {
  [ -n "${1:-}" ] || { echo "Usage: pkg <name|path> [--cd-only] [--hou [VER|latest]]" >&2; return 1; }
  local target="$1"; shift

  local cd_only=0 want_hou=0 ver=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --cd-only) cd_only=1 ;;
      --hou) want_hou=1; [ -n "${2:-}" ] && [ "${2#--}" = "$2" ] && { ver="$2"; shift; } ;;
      --hou=*) want_hou=1; ver="${1#--hou=}" ;;
      *) echo "pkg: unknown flag '$1'" >&2; return 1 ;;
    esac
    shift
  done

  local root
  root="$(_apogee_pkg_resolve "$target")" || { echo "pkg: not found → $target" >&2; return 1; }
  cd "$root" || return 1

  [ "$cd_only" = "1" ] && return 0

  if [ "$want_hou" = "1" ]; then
    echo "pkg --hou is a placeholder in Apogee right now (Houdini wiring comes later)." >&2
    return 2
  fi

  if [ -f pyproject.toml ]; then
    if [ "${APOGEE_PLATFORM:-}" = "linux" ] && [ "${APOGEE_USE_CONDA:-0}" = "1" ] && command -v conda >/dev/null 2>&1; then
      _apogee_py_deactivate
      conda activate "$(basename "$root")" || return 1
    else
      _apogee_uv_activate_in_project "$root" || return 1
    fi
  fi
}
