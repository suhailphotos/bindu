# apogee/functions/python_env.sh
# UV-first python env + pkg (bash)

: "${APOGEE_UV_VENV_ROOT:=$HOME/.venvs}"
: "${APOGEE_UV_DEFAULT_PY:=auto-houdini}"

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
    root="$(git -C . rev-parse --show-toplevel 2>/dev/null)" && [ -f "$root/pyproject.toml" ] && { echo "$root"; return 0; }
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

_apogee_uv_default_python_spec() {
  local mode="${APOGEE_UV_DEFAULT_PY:-auto-houdini}"
  if [ "$mode" != "auto-houdini" ] && [ -n "$mode" ]; then
    echo "$mode"; return 0
  fi
  command -v python3 >/dev/null 2>&1 && command -v python3 || echo "3"
}

_apogee_uv_desired_python_for_project() {
  local root="$1" spec=""
  spec="$(cd "$root" && command uv python find --project 2>/dev/null)" || true
  [ -n "$spec" ] && echo "$spec" || _apogee_uv_default_python_spec
}

_apogee_uv_activate_in_project() {
  local root="$1"
  [ -d "$root" ] || { echo "Project not found: $root" >&2; return 1; }
  cd "$root" || return 1

  _apogee_py_deactivate

  command -v uv >/dev/null 2>&1 || { echo "uv not found on PATH" >&2; return 127; }

  local envroot="${UV_PROJECT_ENVIRONMENT:-${APOGEE_UV_VENV_ROOT}/$(basename "$root")}"
  export UV_PROJECT_ENVIRONMENT="$envroot"

  local want_spec; want_spec="$(_apogee_uv_desired_python_for_project "$root")"

  local q=""
  [ "${APOGEE_UV_QUIET:-0}" = "1" ] && q="-q"

  if [ ! -x "$envroot/bin/python" ]; then
    rm -rf "$envroot" 2>/dev/null || true
    command uv venv --python "$want_spec" $q || return 1
    if [ -f uv.lock ]; then command uv sync --frozen $q; else command uv lock $q && command uv sync $q; fi
  else
    if [ "${APOGEE_UV_SYNC_ON_ACTIVATE:-0}" = "1" ] || [ "${APOGEE_UV_FORCE_SYNC:-0}" = "1" ]; then
      if [ -f uv.lock ]; then command uv sync --frozen $q; else command uv lock $q && command uv sync $q; fi
    fi
  fi

  # standard venv activate
  # shellcheck disable=SC1090
  . "$envroot/bin/activate"
}

_apogee_pkg_root() {
  if [ -n "${PACKAGES:-}" ]; then echo "$PACKAGES"; return 0; fi
  if [ -n "${MATRIX:-}" ]; then echo "$MATRIX/packages"; return 0; fi
  echo "$HOME/packages"
}

_apogee_pkg_resolve() {
  local arg="$1" root; root="$(_apogee_pkg_root)"
  [ -d "$arg" ] && { cd "$arg" >/dev/null 2>&1 && pwd && return 0; }
  [ -d "$root/$arg" ] && { echo "$root/$arg"; return 0; }
  # case-insensitive scan
  local d
  for d in "$root"/*; do
    [ -d "$d" ] || continue
    [ "$(printf '%s' "$(basename "$d")" | tr '[:upper:]' '[:lower:]')" = "$(printf '%s' "$arg" | tr '[:upper:]' '[:lower:]')" ] && { echo "$d"; return 0; }
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

  local root; root="$(_apogee_pkg_resolve "$target")" || { echo "pkg: not found → $target" >&2; return 1; }
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
