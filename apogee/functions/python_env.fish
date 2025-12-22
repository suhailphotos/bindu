# apogee/functions/python_env.fish
# UV-first python env + pkg (fish)

set -q APOGEE_UV_VENV_ROOT; or set -gx APOGEE_UV_VENV_ROOT "$HOME/.venvs"
set -q APOGEE_UV_DEFAULT_PY; or set -gx APOGEE_UV_DEFAULT_PY "auto-houdini"

function env_off
  if type -q conda
    if test -n "$CONDA_SHLVL"; and test "$CONDA_SHLVL" -gt 0
      while test "$CONDA_SHLVL" -gt 0
        conda deactivate >/dev/null 2>&1; or break
      end
    end
  end
  if set -q VIRTUAL_ENV
    if functions -q deactivate
      deactivate >/dev/null 2>&1
    end
  end
end

function __apogee_uv_project_root
  if type -q git
    set -l root (git -C . rev-parse --show-toplevel 2>/dev/null)
    if test -n "$root"; and test -f "$root/pyproject.toml"
      echo "$root"
      return 0
    end
  end
  set -l d (pwd)
  while test "$d" != "/"
    if test -f "$d/pyproject.toml"
      echo "$d"
      return 0
    end
    set d (path dirname "$d")
  end
  return 1
end

function __apogee_uv_env_for
  set -l root $argv[1]
  echo "$APOGEE_UV_VENV_ROOT/"(basename "$root")
end

function __apogee_uv_set_envvar --on-variable PWD
  set -l root (__apogee_uv_project_root)
  if test $status -eq 0
    set -gx UV_PROJECT_ENVIRONMENT (__apogee_uv_env_for "$root")
  else
    set -e UV_PROJECT_ENVIRONMENT
  end
end

function uv
  __apogee_uv_set_envvar
  command uv $argv
end

function uvp
  if set -q UV_PROJECT_ENVIRONMENT
    echo $UV_PROJECT_ENVIRONMENT
  else
    echo "(unset)"
  end
end

function __apogee_uv_activate_in_project
  set -l root $argv[1]
  test -d "$root"; or begin
    echo "Project not found: $root" 1>&2
    return 1
  end

  cd "$root"; or return 1
  env_off

  type -q uv; or begin
    echo "uv not found on PATH" 1>&2
    return 127
  end

  set -l envroot "$UV_PROJECT_ENVIRONMENT"
  if test -z "$envroot"
    set envroot "$APOGEE_UV_VENV_ROOT/"(basename "$root")
    set -gx UV_PROJECT_ENVIRONMENT "$envroot"
  end

  set -l q
  if test "$APOGEE_UV_QUIET" = "1"
    set q "-q"
  end

  if not test -x "$envroot/bin/python"
    rm -rf "$envroot" >/dev/null 2>&1
    command uv venv --python "$APOGEE_UV_DEFAULT_PY" $q; or return 1
    if test -f uv.lock
      command uv sync --frozen $q
    else
      command uv lock $q; and command uv sync $q
    end
  else
    if test "$APOGEE_UV_SYNC_ON_ACTIVATE" = "1"; or test "$APOGEE_UV_FORCE_SYNC" = "1"
      if test -f uv.lock
        command uv sync --frozen $q
      else
        command uv lock $q; and command uv sync $q
      end
    end
  end

  if test -f "$envroot/bin/activate.fish"
    source "$envroot/bin/activate.fish"
  else if test -f "$envroot/bin/activate"
    source "$envroot/bin/activate"
  end
end

function __apogee_pkg_root
  if set -q PACKAGES; and test -n "$PACKAGES"
    echo "$PACKAGES"
    return 0
  end
  if set -q MATRIX; and test -n "$MATRIX"
    echo "$MATRIX/packages"
    return 0
  end
  echo "$HOME/packages"
end

function __apogee_pkg_resolve
  set -l arg $argv[1]
  set -l root (__apogee_pkg_root)

  if test -d "$arg"
    echo (realpath "$arg")
    return 0
  end

  if test -d "$root/$arg"
    echo "$root/$arg"
    return 0
  end

  for d in $root/*
    test -d "$d"; or continue
    if test (string lower (basename "$d")) = (string lower "$arg")
      echo "$d"
      return 0
    end
  end
  return 1
end

function pkg
  set -l target $argv[1]
  test -n "$target"; or begin
    echo "Usage: pkg <name|path> [--cd-only] [--hou [VER|latest]]" 1>&2
    return 1
  end

  set -l cd_only 0
  set -l want_hou 0

  for a in $argv[2..-1]
    switch $a
      case --cd-only
        set cd_only 1
      case --hou --hou=*
        set want_hou 1
      case '*'
        echo "pkg: unknown flag '$a'" 1>&2
        return 1
    end
  end

  set -l root (__apogee_pkg_resolve "$target"); or begin
    echo "pkg: not found → $target" 1>&2
    return 1
  end

  cd "$root"; or return 1
  test $cd_only -eq 1; and return 0

  if test $want_hou -eq 1
    echo "pkg --hou is a placeholder in Apogee right now (Houdini wiring comes later)." 1>&2
    return 2
  end

  if test -f pyproject.toml
    __apogee_uv_activate_in_project "$root"
  end
end
