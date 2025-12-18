# uv helpers (sh family)

# Ensure tool bin dir exists so prepend_if_exists can succeed next shell start
[ -n "${UV_TOOL_BIN_DIR:-}" ] && mkdir -p "$UV_TOOL_BIN_DIR" 2>/dev/null || true

_apogee_uv_project_root() {
  # Prefer git root if it has pyproject.toml
  if root="$(git -C . rev-parse --show-toplevel 2>/dev/null)" && [ -f "$root/pyproject.toml" ]; then
    printf '%s\n' "$root"; return 0
  fi

  d="$PWD"
  while [ "$d" != "/" ] && [ -n "$d" ]; do
    if [ -f "$d/pyproject.toml" ]; then
      printf '%s\n' "$d"; return 0
    fi
    d="${d%/*}"
    [ -z "$d" ] && d="/"
  done
  return 1
}

_apogee_uv_env_for() {
  root="$1"
  base="${root##*/}"
  printf '%s/%s\n' "${APOGEE_UV_VENV_ROOT:-$HOME/.venvs}" "$base"
}

_apogee_uv_set_envvar() {
  root="$(_apogee_uv_project_root)" || { unset UV_PROJECT_ENVIRONMENT; return 0; }
  UV_PROJECT_ENVIRONMENT="$(_apogee_uv_env_for "$root")"
  export UV_PROJECT_ENVIRONMENT
}

# Wrapper: make sure UV_PROJECT_ENVIRONMENT is set whenever uv runs
uv() {
  _apogee_uv_set_envvar
  command uv "$@"
}

uvp() { printf '%s\n' "${UV_PROJECT_ENVIRONMENT:-"(unset)"}"; }

uvensure() {
  # mirror your Orbit behavior
  if [ -f uv.lock ]; then
    uv sync --frozen
  else
    uv lock && uv sync
  fi
}
