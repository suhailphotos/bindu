# If mac already has pbcopy/pbpaste, do not override.
if type -q pbcopy; and type -q pbpaste
    exit 0
end

function __apogee_have
    command -v $argv[1] >/dev/null 2>&1
end

function __apogee_clip_have_wayland
    test -n "$WAYLAND_DISPLAY"
    or return 1
    set -l sock "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY"
    test -S "$sock"
end

function __apogee_clip_have_x11
    test -n "$DISPLAY"
end

function __apogee_osc52_copy
    set -l data (base64 | tr -d '\r\n')
    if set -q TMUX
        printf '\ePtmux;\e]52;c;%s\a\e\\' $data > /dev/tty
    else
        printf '\e]52;c;%s\a' $data > /dev/tty
    end
end

function pbcopy
    if __apogee_have clip.exe
        cat | clip.exe
        return $status
    end
    if __apogee_clip_have_wayland; and __apogee_have wl-copy
        wl-copy
        return $status
    end
    if __apogee_clip_have_x11; and __apogee_have xclip
        xclip -selection clipboard
        return $status
    end
    if __apogee_clip_have_x11; and __apogee_have xsel
        xsel --clipboard --input
        return $status
    end
    __apogee_osc52_copy
end

function pbpaste
    if __apogee_clip_have_wayland; and __apogee_have wl-paste
        wl-paste -n
        return $status
    end
    if __apogee_clip_have_x11; and __apogee_have xclip
        xclip -selection clipboard -o
        return $status
    end
    if __apogee_clip_have_x11; and __apogee_have xsel
        xsel --clipboard --output
        return $status
    end
    if __apogee_have powershell.exe
        powershell.exe -NoProfile -Command 'Get-Clipboard' 2>/dev/null
        return $status
    end
    echo "pbpaste: no clipboard program available" >&2
    return 1
end
