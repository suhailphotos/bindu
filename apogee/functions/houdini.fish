# apogee/functions/houdini.fish

if test "$APOGEE_HAS_HOUDINI" != "1"
  function hou
    echo "Houdini not detected on this host."
    return 1
  end
  exit
end

function __hou_platform
  if test (uname) = "Darwin"
    echo mac
    return
  end
  if test -r /proc/version; and string match -qi "*microsoft*" (cat /proc/version)
    echo wsl
    return
  end
  echo linux
end

function __hou_versions
  set plat (__hou_platform)
  if test "$plat" = "mac"
    ls -1d /Applications/Houdini/Houdini* 2>/dev/null | sed 's|.*/Houdini||' | sort -r
  else
    ls -1d /opt/hfs* 2>/dev/null | sed 's|.*/hfs||' | sort -r
  end
end

function __hou_pick_version --argument-names want
  if test -n "$want"; and test "$want" != "latest"
    echo $want
    return
  end
  if set -q APOGEE_HOUDINI_VERSION; and test -n "$APOGEE_HOUDINI_VERSION"
    echo $APOGEE_HOUDINI_VERSION
    return
  end
  __hou_versions | head -n1
end

function __hou_paths --argument-names ver
  set plat (__hou_platform)
  if test "$plat" = "mac"
    set root "/Applications/Houdini/Houdini$ver"
    set RES "$root/Frameworks/Houdini.framework/Versions/Current/Resources"
    set PYBIN "$root/Frameworks/Houdini.framework/Versions/Current/Resources/Frameworks/Python.framework/Versions/Current/bin/python3"
    set HFS "$root/Frameworks/Houdini.framework/Versions/Current"
    test -x "$PYBIN"; and test -d "$RES"; or return 1
  else
    set HFS "/opt/hfs$ver"
    test -d "$HFS"; or return 1
    set PYBIN ""
    for py in "$HFS/bin/python3.11" "$HFS/bin/python3.10" "$HFS/bin/python3"
      if test -x "$py"
        set PYBIN "$py"
        break
      end
    end
    test -n "$PYBIN"; or return 1
    set RES "$HFS"
  end

  echo "RES=$RES"
  echo "HFS=$HFS"
  echo "PYBIN=$PYBIN"
end

function __hou_pref_dir_for_version --argument-names ver
  set mm (string replace -r '\.[0-9]+$' '' "$ver")
  set plat (__hou_platform)
  switch $plat
    case mac
      echo "$HOME/Library/Preferences/houdini/$mm"
    case wsl
      echo "$HOME/Documents/houdini$mm"
    case '*'
      echo "$HOME/houdini$mm"
  end
end

function hou
  set cmd (count $argv); and echo $argv[1]; or echo help
  set -e argv[1]

  set req_ver ""
  if test (count $argv) -ge 1
    if string match -rq '^(latest|[0-9]+\.[0-9]+\.[0-9]+)$' -- $argv[1]
      set req_ver $argv[1]
      set -e argv[1]
    end
  end

  switch $cmd
    case versions
      __hou_versions
    case python prefs use patch pkgshim doctor
      set ver (__hou_pick_version $req_ver)
      test -n "$ver"; or begin; echo "Couldn’t resolve Houdini version."; return 1; end

      set kv (__hou_paths $ver); or begin; echo "Couldn’t resolve paths for $ver"; return 1; end
      for line in $kv
        set parts (string split -m1 '=' $line)
        set -gx $parts[1] $parts[2]
      end

      switch $cmd
        case python
          echo $PYBIN
        case prefs
          set pref (__hou_pref_dir_for_version $ver)
          set -gx HOUDINI_USER_PREF_DIR $pref
          mkdir -p $pref
          echo "HOUDINI_USER_PREF_DIR=$HOUDINI_USER_PREF_DIR"
        case use
          # project root walk
          set d (pwd)
          while test "$d" != "/"
            if test -f "$d/pyproject.toml"
              break
            end
            set d (dirname $d)
          end
          test -f "$d/pyproject.toml"; or begin; echo "Not inside a project (pyproject.toml not found)."; return 1; end
          cd $d

          set envroot "$APOGEE_UV_VENV_ROOT"/(basename $d)
          if test -z "$APOGEE_UV_VENV_ROOT"
            set envroot "$HOME/.venvs"/(basename $d)
          end
          set -gx UV_PROJECT_ENVIRONMENT $envroot

          set q ""
          if test "$APOGEE_UV_QUIET" = "1"
            set q "-q"
          end

          if test -x "$envroot/bin/python"
            set cur_py ( "$envroot/bin/python" -c 'import sys; print(sys.executable)' )
            if test "$cur_py" != "$PYBIN"
              echo "Recreating env with SideFX Python…"
              rm -rf $envroot
              uv venv --python $PYBIN $q; or return 1
              if test -f uv.lock
                uv sync --frozen $q; or return 1
              else
                uv lock $q; and uv sync $q; or return 1
              end
            end
          else
            uv venv --python $PYBIN $q; or return 1
            if test -f uv.lock
              uv sync --frozen $q; or return 1
            else
              uv lock $q; and uv sync $q; or return 1
            end
          end

          if test -f "$envroot/bin/activate.fish"
            source "$envroot/bin/activate.fish"
          end
          echo "hou use: interpreter → $PYBIN"
        case patch
          set d (pwd)
          while test "$d" != "/"
            if test -f "$d/pyproject.toml"
              break
            end
            set d (dirname $d)
          end
          test -f "$d/pyproject.toml"; or begin; echo "Not inside a project (pyproject.toml not found)."; return 1; end

          set envroot "$APOGEE_UV_VENV_ROOT"/(basename $d)
          if test -z "$APOGEE_UV_VENV_ROOT"
            set envroot "$HOME/.venvs"/(basename $d)
          end

          set pref (__hou_pref_dir_for_version $ver)
          set -gx HOUDINI_USER_PREF_DIR $pref
          mkdir -p $pref

          test -x "$envroot/bin/python"; or begin; echo "No env yet; run 'hou use' first."; return 1; end
          set site ( "$envroot/bin/python" -c 'import sysconfig; print(sysconfig.get_paths().get("purelib",""))' )
          set envfile "$pref/houdini.env"
          touch $envfile
          if not grep -qF "$site" $envfile
            printf 'PYTHONPATH="$PYTHONPATH:%s"\n' "$site" >> $envfile
            echo "→ Added site-packages to $envfile"
          else
            echo "→ Site-packages already present in $envfile"
          end
        case pkgshim
          set d (pwd)
          while test "$d" != "/"
            if test -f "$d/pyproject.toml"
              break
            end
            set d (dirname $d)
          end
          test -f "$d/pyproject.toml"; or begin; echo "Not inside a project (pyproject.toml not found)."; return 1; end

          set envroot "$APOGEE_UV_VENV_ROOT"/(basename $d)
          if test -z "$APOGEE_UV_VENV_ROOT"
            set envroot "$HOME/.venvs"/(basename $d)
          end

          set pref (__hou_pref_dir_for_version $ver)
          set -gx HOUDINI_USER_PREF_DIR $pref
          mkdir -p "$pref/packages"

          test -x "$envroot/bin/python"; or begin; echo "No env yet; run 'hou use' first."; return 1; end
          set site ( "$envroot/bin/python" -c 'import sysconfig; print(sysconfig.get_paths().get("purelib",""))' )

          set jsonfile "$pref/packages/98_uv_site.json"
          printf "{\n  \"enable\": true,\n  \"load_package_once\": true,\n  \"env\": [{ \"PYTHONPATH\": \"\\\${PYTHONPATH}:$site\" }]\n}\n" > $jsonfile
          echo "→ Wrote dev shim: $jsonfile"
          echo "Dev package shim ready (Houdini will pick it up next launch)."
        case doctor
          echo "Resolved:"
          echo "  Version : $ver"
          echo "  RES     : $RES"
          echo "  HFS     : $HFS"
          echo "  PYBIN   : $PYBIN"
      end
    case '*'
      echo "hou — SideFX/Houdini helpers"
      echo "Usage: hou versions | python|prefs|use|pkgshim|patch|doctor [VER|latest]"
  end
end
