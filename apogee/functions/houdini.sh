# apogee/functions/houdini.sh

if [ "${APOGEE_HAS_HOUDINI:-0}" != "1" ]; then
  hou() { echo "Houdini not detected on this host."; return 1; }
  return 0 2>/dev/null || exit 0
fi

_hou_platform() {
  case "$(uname -s 2>/dev/null | tr '[:upper:]' '[:lower:]')" in
    darwin*) echo mac ;;
    linux*)
      if [ -r /proc/version ] && grep -qi microsoft /proc/version 2>/dev/null; then
        echo wsl
      else
        echo linux
      fi
      ;;
    *) echo other ;;
  esac
}

_hou_project_root() {
  d="${1:-$(pwd)}"
  while [ "$d" != "/" ] && [ -n "$d" ]; do
    if [ -f "$d/pyproject.toml" ]; then echo "$d"; return 0; fi
    d="$(dirname "$d")"
  done
  return 1
}

_hou_versions() {
  plat="$(_hou_platform)"
  if [ "$plat" = "mac" ]; then
    ls -1d /Applications/Houdini/Houdini* 2>/dev/null \
      | sed 's|.*/Houdini||' \
      | LC_ALL=C sort -t . -k1,1nr -k2,2nr -k3,3nr
  else
    ls -1d /opt/hfs* 2>/dev/null \
      | sed 's|.*/hfs||' \
      | LC_ALL=C sort -t . -k1,1nr -k2,2nr -k3,3nr
  fi
}

_hou_pick_version() {
  want="$1"
  if [ -n "$want" ] && [ "$want" != "latest" ]; then echo "$want"; return 0; fi
  if [ -n "${APOGEE_HOUDINI_VERSION:-}" ]; then echo "$APOGEE_HOUDINI_VERSION"; return 0; fi
  _hou_versions | head -n1
}

_hou_paths() {
  ver="$1"
  plat="$(_hou_platform)"

  if [ "$plat" = "mac" ]; then
    root="/Applications/Houdini/Houdini${ver}"
    RES="$root/Frameworks/Houdini.framework/Versions/Current/Resources"
    PYBIN="$root/Frameworks/Houdini.framework/Versions/Current/Resources/Frameworks/Python.framework/Versions/Current/bin/python3"
    HFS="$root/Frameworks/Houdini.framework/Versions/Current"
    [ -x "$PYBIN" ] && [ -d "$RES" ] || return 1
  else
    HFS="/opt/hfs${ver}"
    [ -d "$HFS" ] || return 1
    PYBIN=""
    for py in "$HFS/bin/python3.11" "$HFS/bin/python3.10" "$HFS/bin/python3"; do
      if [ -x "$py" ]; then PYBIN="$py"; break; fi
    done
    [ -n "$PYBIN" ] || return 1
    RES="$HFS"
  fi

  echo "VER=$ver"
  echo "RES=$RES"
  echo "HFS=$HFS"
  echo "PYBIN=$PYBIN"
}

_hou_pref_dir_for_version() {
  ver="$1"
  mm="${ver%.*}"
  plat="$(_hou_platform)"
  case "$plat" in
    mac)  echo "$HOME/Library/Preferences/houdini/$mm" ;;
    wsl)  echo "$HOME/Documents/houdini$mm" ;;
    *)    echo "$HOME/houdini$mm" ;;
  esac
}

_hou_site_packages_for_venv() {
  venv="$1"
  [ -x "$venv/bin/python" ] || return 1
  "$venv/bin/python" -c 'import sysconfig; print(sysconfig.get_paths().get("purelib",""))'
}

_hou_source_setup() {
  RES="$1"; HFS="$2"
  plat="$(_hou_platform)"
  if [ "$plat" = "mac" ]; then
    [ -r "$RES/houdini_setup" ] || { echo "Missing $RES/houdini_setup"; return 1; }
    # shellcheck disable=SC1090
    . "$RES/houdini_setup"
  else
    [ -r "$HFS/houdini_setup" ] || { echo "Missing $HFS/houdini_setup"; return 1; }
    # shellcheck disable=SC1090
    . "$HFS/houdini_setup"
  fi
}

_hou_smoke_import() {
  pybin="$1"; license="${2:-}"; release="${3:-0}"
  extra=""
  [ -n "$license" ] && extra="import os; os.environ['HOUDINI_SCRIPT_LICENSE'] = '${license}'; "
  "$pybin" - <<PY || return 1
${extra}import hou
print("hou ok:", hou.applicationVersionString())
${release:+hou.releaseLicense()}
PY
}

_hou_write_pkg_json() {
  prefdir="$1"; site="$2"
  mkdir -p "$prefdir/packages" || return 1
  cat >"$prefdir/packages/98_uv_site.json" <<JSON
{
  "enable": true,
  "load_package_once": true,
  "env": [{ "PYTHONPATH": "\${PYTHONPATH}:${site}" }]
}
JSON
  echo "→ Wrote dev shim: $prefdir/packages/98_uv_site.json"
}

# set defaults (don’t overwrite user choices)
if [ -z "${APOGEE_HOUDINI_VERSION:-}" ]; then
  APOGEE_HOUDINI_VERSION="$(_hou_versions | head -n1)"
fi
if [ -n "${APOGEE_HOUDINI_VERSION:-}" ] && [ -z "${APOGEE_HOUDINI_PREF_DEFAULT:-}" ]; then
  APOGEE_HOUDINI_PREF_DEFAULT="$(_hou_pref_dir_for_version "$APOGEE_HOUDINI_VERSION")"
fi
export APOGEE_HOUDINI_VERSION APOGEE_HOUDINI_PREF_DEFAULT

hou() {
  cmd="${1:-help}"; shift 2>/dev/null || true
  req_ver=""
  case "${1:-}" in
    latest|[0-9]*.[0-9]*.[0-9]*) req_ver="$1"; shift ;;
  esac

  case "$cmd" in
    versions)
      _hou_versions || { echo "No Houdini versions found." >&2; return 1; }
      ;;
    python|prefs|use|patch|import|env|doctor|pkgshim)
      ver="$(_hou_pick_version "${req_ver:-}")" || { echo "Couldn’t resolve Houdini version."; return 1; }
      kv="$(_hou_paths "$ver")" || { echo "Couldn’t resolve paths for $ver"; return 1; }
      # shellcheck disable=SC2086
      eval "$kv"

      case "$cmd" in
        python) echo "$PYBIN" ;;
        prefs)
          pref="$(_hou_pref_dir_for_version "$ver")"
          export HOUDINI_USER_PREF_DIR="$pref"
          mkdir -p "$pref"
          echo "HOUDINI_USER_PREF_DIR=$HOUDINI_USER_PREF_DIR"
          ;;
        use)
          proj_root="${HOU_PROJECT_ROOT:-$(_hou_project_root)}"
          [ -n "$proj_root" ] || { echo "Not inside a project (pyproject.toml not found)."; return 1; }
          cd "$proj_root" || return 1

          envroot="${APOGEE_UV_VENV_ROOT:-$HOME/.venvs}/$(basename "$proj_root")"
          export UV_PROJECT_ENVIRONMENT="$envroot"

          q=""
          [ "${APOGEE_UV_QUIET:-0}" = "1" ] && q="-q"

          if [ -x "$envroot/bin/python" ]; then
            cur_py="$("$envroot/bin/python" -c 'import sys; print(sys.executable)')"
            if [ "$cur_py" != "$PYBIN" ]; then
              echo "Recreating env with SideFX Python…"
              rm -rf "$envroot"
              uv venv --python "$PYBIN" $q || return 1
              if [ -f uv.lock ]; then uv sync --frozen $q; else uv lock $q && uv sync $q; fi
            fi
          else
            uv venv --python "$PYBIN" $q || return 1
            if [ -f uv.lock ]; then uv sync --frozen $q; else uv lock $q && uv sync $q; fi
          fi

          # shellcheck disable=SC1090
          . "$envroot/bin/activate"
          echo "hou use: interpreter → $PYBIN"
          ;;
        patch)
          proj_root="${HOU_PROJECT_ROOT:-$(_hou_project_root)}"
          [ -n "$proj_root" ] || { echo "Not inside a project (pyproject.toml not found)."; return 1; }
          envroot="${APOGEE_UV_VENV_ROOT:-$HOME/.venvs}/$(basename "$proj_root")"
          pref="$(_hou_pref_dir_for_version "$ver")"
          export HOUDINI_USER_PREF_DIR="$pref"
          mkdir -p "$pref"

          site="$(_hou_site_packages_for_venv "$envroot")" || { echo "No env yet; run 'hou use' or 'uv venv' first."; return 1; }
          envfile="$pref/houdini.env"; : > /dev/null; touch "$envfile"

          if ! grep -qF "$site" "$envfile"; then
            printf 'PYTHONPATH="$PYTHONPATH:%s"\n' "$site" >>"$envfile"
            echo "→ Added site-packages to $envfile"
          else
            echo "→ Site-packages already present in $envfile"
          fi
          ;;
        pkgshim)
          proj_root="${HOU_PROJECT_ROOT:-$(_hou_project_root)}"
          [ -n "$proj_root" ] || { echo "Not inside a project (pyproject.toml not found)."; return 1; }
          envroot="${APOGEE_UV_VENV_ROOT:-$HOME/.venvs}/$(basename "$proj_root")"
          pref="$(_hou_pref_dir_for_version "$ver")"
          export HOUDINI_USER_PREF_DIR="$pref"
          mkdir -p "$pref"

          site="$(_hou_site_packages_for_venv "$envroot")" || { echo "No env yet; run 'hou use' or 'uv venv' first."; return 1; }
          _hou_write_pkg_json "$pref" "$site"
          echo "Dev package shim ready (Houdini will pick it up next launch)."
          ;;
        import)
          license=""; release=0
          while [ $# -gt 0 ]; do
            case "$1" in
              --license) shift; license="${1:-}" ;;
              --license=*) license="${1#--license=}" ;;
              --release) release=1 ;;
            esac
            shift
          done
          _hou_source_setup "$RES" "$HFS" || return 1
          _hou_smoke_import "$PYBIN" "$license" "$release"
          ;;
        env)
          _hou_source_setup "$RES" "$HFS" || return 1
          echo "houdini_setup sourced for $ver (HFS=$HFS)"
          ;;
        doctor)
          echo "Resolved:"
          echo "  Version : $ver"
          echo "  RES     : $RES"
          echo "  HFS     : $HFS"
          echo "  PYBIN   : $PYBIN"
          if _hou_source_setup "$RES" "$HFS" >/dev/null 2>&1; then
            echo "  setup   : OK (houdini_setup)"
          else
            echo "  setup   : FAILED"
          fi
          ;;
      esac
      ;;
    help|*)
      cat <<'EOF'
hou — SideFX/Houdini helpers for uv projects

Usage:
  hou versions
  hou python  [VER|latest]
  hou prefs   [VER|latest]
  hou use     [VER|latest]
  hou pkgshim [VER|latest]
  hou patch   [VER|latest]
  hou import  [VER|latest] [--license hescape|batch] [--release]
  hou env     [VER|latest]
  hou doctor  [VER|latest]
EOF
      ;;
  esac
}
