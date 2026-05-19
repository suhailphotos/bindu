function smb-volumes
    set -l cmd status
    if test (count $argv) -gt 0
        set cmd $argv[1]
    end

    set -l pause_file "$HOME/.config/apogee/automount-smb.paused"
    set -l mount_script "$HOME/.local/bin/automount-smb-volumes.zsh"
    set -l log_file "$HOME/Library/Logs/automount-smb-volumes.log"

    switch $cmd
        case mount
            rm -f "$pause_file"
            "$mount_script"

        case unmount
            touch "$pause_file"
            umount "$HOME/Mounts/dataLib" 2>/dev/null; or true
            umount "$HOME/Mounts/whisk" 2>/dev/null; or true

        case remount
            touch "$pause_file"
            umount "$HOME/Mounts/dataLib" 2>/dev/null; or true
            umount "$HOME/Mounts/whisk" 2>/dev/null; or true
            rm -f "$pause_file"
            "$mount_script"

        case pause
            touch "$pause_file"
            echo "SMB automount paused."

        case resume
            rm -f "$pause_file"
            "$mount_script"

        case status
            echo "Automount:"
            if test -f "$pause_file"
                echo "  paused"
            else
                echo "  active"
            end

            echo
            echo "Mounted SMB volumes:"
            mount | grep -E "$HOME/Mounts/(dataLib|whisk)"
            or echo "  none"

            echo
            echo "Mount folders:"
            ls -ld "$HOME/Mounts/dataLib" "$HOME/Mounts/whisk" 2>/dev/null
            or true

            echo
            echo "Environment:"
            if set -q DATALIB
                echo "  DATALIB=$DATALIB"
            else
                echo "  DATALIB=unset"
            end

            if set -q WHISK
                echo "  WHISK=$WHISK"
            else
                echo "  WHISK=unset"
            end

        case logs
            tail -n 100 "$log_file"

        case '*'
            echo "Usage: smb-volumes {mount|unmount|remount|pause|resume|status|logs}"
            return 1
    end
end
