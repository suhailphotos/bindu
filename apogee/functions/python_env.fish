# apogee/functions/python_env.fish
# UV-first python env + pkg (fish)
#
# Host-mimic policy:
# - Do NOT set UV_PYTHON_INSTALL_DIR here.
# - Let uv use its default per-user layout:
#     ~/.local/share/uv/python
#     ~/.local/share/uv/tools
#     ~/.local/share/uv/bin
# - Ensure requested Python exists on-demand (uv python install <ver>), idempotent.
# - Keep UV_PROJECT_ENVIRONMENT updated automatically.
# - Prompt env name for Starship comes from PROMPT_PY_ENV_NAME.

# ---- defaults (only if not set) --------------------------------------------

set -q APOGEE_UV_VENV_ROOT;        or set -gx APOGEE_UV_VENV_ROOT "$HOME/.venvs"
set -q APOGEE_UV_DEFAULT_PY;       or set -gx APOGEE_UV_DEFAULT_PY "auto-houdini"
set -q APOGEE_UV_QUIET;            or set -gx APOGEE_UV_QUIET "0"
set -q APOGEE_UV_SYNC_ON_ACTIVATE; or set -gx APOGEE_UV_SYNC_ON_ACTIVATE "0"
set -q APOGEE_UV_FORCE_SYNC;       or set -gx APOGEE_UV_FORCE_SYNC "0"

# ---- deactivate helpers -----------------------------------------------------

function _apogee_py_deactivate
  # conda
  if type -q conda
    if set -q CONDA_SHLVL
      while test "$CONDA_SHLVL" -gt 0
        conda deactivate >/dev/null 2>&1; or break
      end
    end
  end

  # venv
  if set -q VIRTUAL_ENV
    if functions -q deactivate
      deactivate >/dev/null 2>&1; or true
    end
  end
end

function env_off
  _apogee_py_deactivate
end

# ---- project root detection -------------------------------------------------

function _apogee_uv_project_root
  # Prefer git root if it contains pyproject.toml
  if type -q git
    set -l root (git -C . rev-parse --show-toplevel 2>/dev/null)
    if test -n "$root"; and test -f "$root/pyproject.toml"
      echo "$root"
      return 0
    end
  end

  # Walk up from PWD
  set -l d "$PWD"
  while test "$d" != "/"
    if test -f "$d/pyproject.toml"
      echo "$d"
      return 0
    end
    set d (dirname "$d")
  end

  return 1
end

function _apogee_uv_env_for
  set -l root "$argv[1]"
  echo "$APOGEE_UV_VENV_ROOT/(basename "$root")"
end

function _apogee_uv_set_envvar
  set -l root (_apogee_uv_project_root)
  if test $status -ne 0
    set -e UV_PROJECT_ENVIRONMENT
    return 0
  end
  set -gx UV_PROJECT_ENVIRONMENT (_apogee_uv_env_for "$root")
end

# ---- uv wrapper -------------------------------------------------------------

functions -q uv; and functions -e uv

function uv
  _apogee_uv_set_envvar
  command uv $argv
end

function uvp
  if set -q UV_PROJECT_ENVIRONMENT
    echo "$UV_PROJECT_ENVIRONMENT"
  else
    echo "(unset)"
  end
end

# ---- version selection helpers ----------------------------------------------

function _apogee_py_mm_to_num
  # "3.11" -> 311
  set -l mm "$argv[1]"
  set -l major (string split -m1 . -- "$mm")[1]
  set -l minor (string split -m1 . -- "$mm")[2]
  echo (math "$major * 100 + $minor")
end

function _apogee_pyproject_requires_python
  set -l root "$argv[1]"
  set -l f "$root/pyproject.toml"
  test -f "$f"; or return 1

  # Grab: requires-python = "...."
  set -l line (command awk -F= '
    $1 ~ /^[[:space:]]*requires-python[[:space:]]*$/ {
      gsub(/^[[:space:]]+|[[:space:]]+$/,"",$2);
      gsub(/"/,"",$2);
      print $2;
      exit
    }
  ' "$f" 2>/dev/null)

  test -n "$line"; or return 1
  echo "$line"
  return 0
end

function _apogee_requires_min_mm
  # spec like ">=3.11,<3.13" -> "3.11"
  set -l spec "$argv[1]"
  echo "$spec" | command sed -nE 's/.*>=\s*([0-9]+)\.([0-9]+).*/\1.\2/p' | head -n1
end

function _apogee_houdini_python_mm
  if type -q hython
    hython -c 'import sys; print(f"{sys.version_info[0]}.{sys.version_info[1]}")' 2>/dev/null
    return $status
  end

  if set -q APOGEE_HOUDINI_DETECT_PATH
    if test -x "$APOGEE_HOUDINI_DETECT_PATH/bin/hython"
      "$APOGEE_HOUDINI_DETECT_PATH/bin/hython" -c 'import sys; print(f"{sys.version_info[0]}.{sys.version_info[1]}")' 2>/dev/null
      return $status
    end
  end

  return 1
end

function _apogee_uv_default_python_spec
  set -l mode "$APOGEE_UV_DEFAULT_PY"

  if test -n "$mode"; and test "$mode" != "auto-houdini"
    echo "$mode"
    return 0
  end

  set -l hou_mm (_apogee_houdini_python_mm 2>/dev/null)
  if test $status -eq 0; and test -n "$hou_mm"
    echo "$hou_mm"
    return 0
  end

  echo "3"
end

function _apogee_uv_pick_python_for_project
  set -l root "$argv[1]"

  if test -f "$root/.python-version"
    # first token
    command awk '{print $1; exit}' "$root/.python-version" | string trim
    return 0
  end

  set -l req (_apogee_pyproject_requires_python "$root" 2>/dev/null)
  set -l min_mm ""
  if test $status -eq 0
    set min_mm (_apogee_requires_min_mm "$req" 2>/dev/null)
  end

  set -l def (_apogee_uv_default_python_spec)
  set -l def_mm "$def"

  if test -n "$min_mm"
    if string match -qr '^[0-9]+\.[0-9]+$' -- "$def_mm"
      if test (_apogee_py_mm_to_num "$def_mm") -ge (_apogee_py_mm_to_num "$min_mm")
        echo "$def_mm"
        return 0
      end
    end
    echo "$min_mm"
    return 0
  end

  echo "$def"
end

function _apogee_uv_pin_python_if_missing
  set -l root "$argv[1]"
  set -l py "$argv[2]"

  string match -qr '^[0-9]+(\.[0-9]+){0,2}$' -- "$py"; or return 0
  test -f "$root/.python-version"; and return 0
  test -w "$root"; or return 0

  command uv python pin "$py" >/dev/null 2>&1; or true
end

function _apogee_uv_ensure_python_installed
  set -l py "$argv[1]"

  string match -qr '^[0-9]+(\.[0-9]+){0,2}$' -- "$py"; or return 0
  type -q uv; or return 0

  command uv python install "$py" >/dev/null 2>&1; or command uv python install "$py"
end

# ---- activation -------------------------------------------------------------

function _apogee_uv_activate_in_project
  set -l root "$argv[1]"
  test -d "$root"; or begin
    echo "Project not found: $root" >&2
    return 1
  end

  cd "$root"; or return 1

  _apogee_py_deactivate
  type -q uv; or begin
    echo "uv not found on PATH" >&2
    return 127
  end

  set -l envroot ""
  if set -q UV_PROJECT_ENVIRONMENT
    set envroot "$UV_PROJECT_ENVIRONMENT"
  else
    set envroot "$APOGEE_UV_VENV_ROOT/(basename "$root")"
  end
  set -gx UV_PROJECT_ENVIRONMENT "$envroot"

  set -l want_spec (_apogee_uv_pick_python_for_project "$root")
  _apogee_uv_pin_python_if_missing "$root" "$want_spec"

  _apogee_uv_ensure_python_installed "$want_spec"; or begin
    echo "uv: failed to install/ensure Python '$want_spec'" >&2
    return 1
  end

  set -l q ""
  if test "$APOGEE_UV_QUIET" = "1"
    set q "-q"
  end

  if not test -x "$envroot/bin/python"
    rm -rf "$envroot" >/dev/null 2>&1; or true

    command uv venv --python "$want_spec" $q; or return 1

    if test -f uv.lock
      command uv sync --frozen $q; or return 1
    else
      command uv lock $q; and command uv sync $q; or return 1
    end
  else
    if test "$APOGEE_UV_SYNC_ON_ACTIVATE" = "1"; or test "$APOGEE_UV_FORCE_SYNC" = "1"
      if test -f uv.lock
        command uv sync --frozen $q; or return 1
      else
        command uv lock $q; and command uv sync $q; or return 1
      end
    end
  end

  # Fish activation script exists in uv venvs
  if test -f "$envroot/bin/activate.fish"
    source "$envroot/bin/activate.fish"
  else if test -f "$envroot/bin/activate"
    # fallback (rare)
    source "$envroot/bin/activate"
  end
end

# ---- Starship env name ------------------------------------------------------

function _apogee_set_prompt_py_env_name
  if set -q VIRTUAL_ENV
    set -gx PROMPT_PY_ENV_NAME (basename "$VIRTUAL_ENV")
    return 0
  end

  if set -q CONDA_DEFAULT_ENV
    set -gx PROMPT_PY_ENV_NAME "$CONDA_DEFAULT_ENV"
    return 0
  end

  set -e PROMPT_PY_ENV_NAME
end

# ---- install prompt hooks (fish-native) ------------------------------------

function _apogee_prompt_hook --on-event fish_prompt
  _apogee_uv_set_envvar
  _apogee_set_prompt_py_env_name
end

# ---- pkg -------------------------------------------------------------------

function _apogee_pkg_root
  if set -q PACKAGES
    echo "$PACKAGES"
    return 0
  end
  if set -q MATRIX
    echo "$MATRIX/packages"
    return 0
  end
  echo "$HOME/packages"
end

function _apogee_pkg_resolve
  set -l arg "$argv[1]"
  set -l root (_apogee_pkg_root)

  if test -d "$arg"
    cd "$arg" >/dev/null 2>&1; and pwd
    return $status
  end

  if test -d "$root/$arg"
    echo "$root/$arg"
    return 0
  end

  for d in "$root"/*
    test -d "$d"; or continue
    set -l dn (string lower (basename "$d"))
    set -l an (string lower "$arg")
    if test "$dn" = "$an"
      echo "$d"
      return 0
    end
  end

  return 1
end

function pkg
  if test (count $argv) -lt 1
    echo "Usage: pkg <name|path> [--cd-only] [--hou [VER|latest]]" >&2
    return 1
  end

  set -l target "$argv[1]"
  set -e argv[1]

  set -l cd_only 0
  set -l want_hou 0
  set -l ver ""

  while test (count $argv) -gt 0
    switch $argv[1]
      case --cd-only
        set cd_only 1
        set -e argv[1]
      case --hou
        set want_hou 1
        set -e argv[1]
        if test (count $argv) -gt 0; and not string match -q -- "--*" "$argv[1]"
          set ver "$argv[1]"
          set -e argv[1]
        end
      case --hou=*
        set want_hou 1
        set ver (string replace -- '--hou=' '' "$argv[1]")
        set -e argv[1]
      case '*'
        echo "pkg: unknown flag '$argv[1]'" >&2
        return 1
    end
  end

  set -l root (_apogee_pkg_resolve "$target")
  test $status -eq 0; or begin
    echo "pkg: not found → $target" >&2
    return 1
  end

  cd "$root"; or return 1

  if test "$cd_only" = "1"
    return 0
  end

  if test "$want_hou" = "1"
    echo "pkg --hou is a placeholder in Apogee right now (Houdini wiring comes later)." >&2
    return 2
  end

  if test -f pyproject.toml
    if test "$APOGEE_PLATFORM" = "linux"; and test "$APOGEE_USE_CONDA" = "1"; and type -q conda
      _apogee_py_deactivate
      conda activate (basename "$root"); or return 1
    else
      _apogee_uv_activate_in_project "$root"; or return 1
    end
  end
end
