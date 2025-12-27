function _nukeutils_root
    if set -q PACKAGES; and test -d "$PACKAGES/nukeUtils"
        echo "$PACKAGES/nukeUtils"; return 0
    end
    if set -q DROPBOX; and test -d "$DROPBOX/matrix/packages/nukeUtils"
        echo "$DROPBOX/matrix/packages/nukeUtils"; return 0
    end
    if test -d "$HOME/Dropbox/matrix/packages/nukeUtils"
        echo "$HOME/Dropbox/matrix/packages/nukeUtils"; return 0
    end
    if test -d "$HOME/Library/CloudStorage/Dropbox/matrix/packages/nukeUtils"
        echo "$HOME/Library/CloudStorage/Dropbox/matrix/packages/nukeUtils"; return 0
    end
    return 1
end

function _nukeutils_prepend_nuke_path
    set -l entry $argv[1]
    if not set -q NUKE_PATH
        set -gx NUKE_PATH $entry
        return 0
    end
    set -l parts (string split ":" -- $NUKE_PATH)
    if contains -- $entry $parts
        return 0
    end
    set -gx NUKE_PATH "$entry:$NUKE_PATH"
end

function _nukeutils_launch
    # Prefer CLI if available
    if type -q nuke
        nuke $argv
        return $status
    end

    # macOS: prefer Apogee's detected .app path
    if type -q open
        if set -q APOGEE_NUKE_DETECT_PATH; and test -d "$APOGEE_NUKE_DETECT_PATH"
            open -a "$APOGEE_NUKE_DETECT_PATH" --args $argv 2>/dev/null
            or open -a "$APOGEE_NUKE_DETECT_PATH" 2>/dev/null
            or begin
                echo "Could not launch Nuke app: $APOGEE_NUKE_DETECT_PATH" >&2
                return 1
            end
            return 0
        end

        # Best-effort fallback: by name only (no version guessing)
        set -l edition (set -q NUKE_EDITION; and echo $NUKE_EDITION; or echo Nuke)
        open -a $edition --args $argv 2>/dev/null
        or open -a $edition 2>/dev/null
        or begin
            echo "Could not launch Nuke app: $edition (and no APOGEE_NUKE_DETECT_PATH)" >&2
            return 1
        end
        return 0
    end

    echo "No 'nuke' command found and no macOS 'open' available." >&2
    return 1
end

function nukeUtils
    set -l cmd $argv[1]
    set -e argv[1]

    if test "$APOGEE_HAS_NUKE" != "1"; and not type -q nuke
        return 1
    end

    set -l root (_nukeutils_root); or begin
        echo "nukeUtils project not found. Expected PACKAGES/nukeUtils (or Dropbox fallback)." >&2
        return 1
    end

    function _nuke_activate --no-scope-shadowing
        if not test -d "$root"
            echo "Project not found: $root" >&2
            return 1
        end
        if test "$PWD" != "$root"
            cd "$root"; or return 1
        end
        if functions -q _uv_activate_in_project
            _uv_activate_in_project "$root"; or return 1
        end
    end

    function _nuke_prefs_and_paths --no-scope-shadowing
        if not set -q NUKE_USER_DIR
            set -gx NUKE_USER_DIR "$HOME/.nuke"
        end
        mkdir -p "$NUKE_USER_DIR" >/dev/null 2>&1

        set -l plugins "$root/plugins"
        if test -d "$plugins"
            _nukeutils_prepend_nuke_path "$plugins"
        end
    end

    switch "$cmd"
        case "-e" "env"
            _nuke_activate; or return 1
            _nuke_prefs_and_paths
            echo "Nuke env ready. root=$root"
        case "" "launch"
            _nuke_activate >/dev/null 2>&1
            _nuke_prefs_and_paths
            _nukeutils_launch $argv
        case "*"
            echo "Usage: nukeUtils [launch] | nukeUtils -e" >&2
            return 1
    end
end
