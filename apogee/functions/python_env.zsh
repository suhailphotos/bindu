# apogee/functions/python_env.zsh
# UV-first python env + pkg (zsh)

# ---------------- Deactivate helpers ----------------

alias deactivate >/dev/null 2>&1 && unalias deactivate

_apogee_py_deactivate() {
  if command -v conda >/dev/null 2>&1 && [[ -n ${CONDA_SHLVL:-} && ${CONDA_SHLVL} -gt 0 ]]; then
    while [[ ${CONDA_SHLVL:-0} -gt 0 ]]; do conda deactivate >/dev/null 2>&1 || break; done
  fi
  if [[ -n ${VIRTUAL_ENV:-} ]] && typeset -f deactivate >/dev/null 2>&1; then
    deactivate >/dev/null 2>&1 || true
  fi
}

env_off() { _apogee_py_deactivate; }

_apogee_deactivate_fallback() {
  if command -v conda >/dev/null 2>&1 && [[ -n ${CONDA_SHLVL:-} && ${CONDA_SHLVL} -gt 0 ]]; then
    conda deactivate; return
  fi
  echo "No virtual environment is active." >&2
  return 1
}

_apogee_install_deactivate_fallback() {
  if [[ -z ${VIRTUAL_ENV:-} && ${CONDA_SHLVL:-0} -eq 0 ]]; then
    alias deactivate >/dev/null 2>&1 && unalias deactivate
    typeset -f deactivate >/dev/null 2>&1 || deactivate() { _apogee_deactivate_fallback "$@"; }
  fi
}

autoload -Uz add-zsh-hook
add-zsh-hook precmd _apogee_install_deactivate_fallback
_apogee_install_deactivate_fallback
alias da='deactivate'

# ---------------- uv project envvar sync ----------------

: ${APOGEE_UV_VENV_ROOT:="$HOME/.venvs"}
: ${APOGEE_UV_DEFAULT_PY:="auto-houdini"}

_apogee_uv_project_root() {
  local root
  if root="$(git -C . rev-parse --show-toplevel 2>/dev/null)"; then
    [[ -f "$root/pyproject.toml" ]] && { echo "$root"; return 0; }
  fi
  local d="$PWD"
  while [[ "$d" != "/" ]]; do
    [[ -f "$d/pyproject.toml" ]] && { echo "$d"; return 0; }
    d="${d:h}"
  done
  return 1
}

_apogee_uv_env_for() {
  local root="$1"
  echo "${APOGEE_UV_VENV_ROOT}/${root:t}"
}

_apogee_uv_set_envvar() {
  local root; root="$(_apogee_uv_project_root)" || { unset UV_PROJECT_ENVIRONMENT; return; }
  export UV_PROJECT_ENVIRONMENT="$(_apogee_uv_env_for "$root")"
}

add-zsh-hook chpwd  _apogee_uv_set_envvar
add-zsh-hook precmd _apogee_uv_set_envvar

uv() {
  _apogee_uv_set_envvar
  command uv "$@"
}

uvp() { print -r -- "${UV_PROJECT_ENVIRONMENT:-"(unset)"}"; }

# ---------------- uv activation ----------------

_apogee_uv_default_python_spec() {
  local mode="${APOGEE_UV_DEFAULT_PY:-auto-houdini}"
  if [[ "$mode" != "auto-houdini" && -n "$mode" ]]; then
    echo "$mode"
    return 0
  fi

  # auto-houdini (placeholder): only works once you export APOGEE_HAS_HOUDINI/APOGEE_HOUDINI_ROOT
  if [[ "${APOGEE_HAS_HOUDINI:-0}" == 1 && -n "${APOGEE_HOUDINI_ROOT:-}" ]]; then
    local pybin=""
    if [[ -x "${APOGEE_HOUDINI_ROOT}/Frameworks/Houdini.framework/Versions/Current/Resources/Frameworks/Python.framework/Versions/Current/bin/python3" ]]; then
      pybin="${APOGEE_HOUDINI_ROOT}/Frameworks/Houdini.framework/Versions/Current/Resources/Frameworks/Python.framework/Versions/Current/bin/python3"
    fi
    if [[ -x "$pybin" ]]; then
      local minor
      minor="$("$pybin" -c 'import sys;print(f"{sys.version_info[0]}.{sys.version_info[1]}")' 2>/dev/null || true)"
      [[ -n "$minor" ]] && { echo "$minor"; return 0; }
    fi
  fi

  local sys; sys="$(command -v python3 2>/dev/null || true)"
  [[ -n "$sys" ]] && { echo "$sys"; return 0; }
  echo "3"
}

_apogee_uv_desired_python_for_project() {
  local root="$1"
  local spec=""
  spec="$( (cd "$root" && command uv python find --project 2>/dev/null) || true )"
  [[ -n "$spec" ]] && echo "$spec" || _apogee_uv_default_python_spec
}

_apogee_uv_activate_in_project() {
  local root="$1"
  [[ -d "$root" ]] || { echo "Project not found: $root" >&2; return 1; }
  cd "$root" || return 1

  _apogee_py_deactivate

  local envroot="${UV_PROJECT_ENVIRONMENT:-${APOGEE_UV_VENV_ROOT}/${root:t}}"
  export UV_PROJECT_ENVIRONMENT="$envroot"

  command -v uv >/dev/null 2>&1 || { echo "uv not found on PATH" >&2; return 127; }

  local want_spec; want_spec="$(_apogee_uv_desired_python_for_project "$root")"
  local need_rebuild=0 cur_ver="" want_ver="" want_path=""

  if [[ -x "$envroot/bin/python" ]]; then
    cur_ver="$("$envroot/bin/python" -c 'import platform;print(platform.python_version())' 2>/dev/null || true)"
    want_path="$(command uv python find "$want_spec" 2>/dev/null || true)"
    [[ -n "$want_path" ]] && want_ver="$("$want_path" -c 'import platform;print(platform.python_version())' 2>/dev/null || true)"
    [[ -z "$cur_ver" || -z "$want_ver" || "$cur_ver" != "$want_ver" ]] && need_rebuild=1
  else
    need_rebuild=1
  fi

  local q=""; (( ${APOGEE_UV_QUIET:-0} )) && q="-q"

  if (( need_rebuild )); then
    rm -rf -- "$envroot" 2>/dev/null || true
    command uv venv --python "$want_spec" $q || return 1
    if [[ -f uv.lock ]]; then command uv sync --frozen $q; else command uv lock $q && command uv sync $q; fi
  elif (( ${APOGEE_UV_SYNC_ON_ACTIVATE:-0} || ${APOGEE_UV_FORCE_SYNC:-0} )); then
    if [[ -f uv.lock ]]; then command uv sync --frozen $q; else command uv lock $q && command uv sync $q; fi
  fi

  source "$envroot/bin/activate"
}

# ---------------- pkg ----------------

_apogee_pkg_root() {
  echo "${PACKAGES:-${MATRIX:-$HOME}/packages}"
}

_apogee_pkg_ci() {
  local needle="$1"
  local root="$(_apogee_pkg_root)"
  for d in "$root"/*; do
    [[ -d $d ]] || continue
    [[ "${d:t:l}" == "${needle:l}" ]] && { echo "$d"; return 0; }
  done
  return 1
}

_apogee_pkg_resolve() {
  local arg="$1"
  local root="$(_apogee_pkg_root)"
  [[ -d "$arg" ]] && { echo "${arg:A}"; return 0; }
  [[ -d "$root/$arg" ]] && { echo "$root/$arg"; return 0; }
  _apogee_pkg_ci "$arg" && return 0
  return 1
}

pkg() {
  emulate -L zsh; setopt pipefail
  [[ -z "${1:-}" ]] && { echo "Usage: pkg <name|path> [--cd-only] [--hou [VER|latest]]"; return 1; }
  local target="$1"; shift

  local cd_only=0 want_hou=0 ver=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --cd-only) cd_only=1 ;;
      --hou) want_hou=1; [[ -n "${2-}" && "${2:0:2}" != "--" ]] && { ver="$2"; shift; } ;;
      --hou=*) want_hou=1; ver="${1#--hou=}" ;;
      *) echo "pkg: unknown flag '$1'"; return 1 ;;
    esac
    shift
  done

  local root; root="$(_apogee_pkg_resolve "$target")" || { echo "pkg: not found → $target"; return 1; }
  cd "$root" || return 1

  (( cd_only )) && return 0

  if (( want_hou )); then
    echo "pkg --hou is a placeholder in Apogee right now (Houdini wiring comes later)." >&2
    return 2
  fi

  if [[ -f pyproject.toml ]]; then
    # Optional linux conda override (same intent as Orbit)
    if [[ "${APOGEE_PLATFORM:-}" == "linux" && "${APOGEE_USE_CONDA:-0}" == 1 ]] && command -v conda >/dev/null 2>&1; then
      _apogee_py_deactivate
      conda activate "${root:t}" || return 1
    else
      _apogee_uv_activate_in_project "$root" || return 1
    fi
  fi
}
