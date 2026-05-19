smb-volumes() {
  local pause_file="$HOME/.config/apogee/automount-smb.paused"
  local mount_script="$HOME/.local/bin/automount-smb-volumes.zsh"
  local log_file="$HOME/Library/Logs/automount-smb-volumes.log"

  case "${1:-status}" in
    mount)
      rm -f "$pause_file"
      "$mount_script"
      ;;

    unmount)
      touch "$pause_file"
      umount "$HOME/Mounts/dataLib" 2>/dev/null || true
      umount "$HOME/Mounts/whisk" 2>/dev/null || true
      ;;

    remount)
      touch "$pause_file"
      umount "$HOME/Mounts/dataLib" 2>/dev/null || true
      umount "$HOME/Mounts/whisk" 2>/dev/null || true
      rm -f "$pause_file"
      "$mount_script"
      ;;

    pause)
      touch "$pause_file"
      echo "SMB automount paused."
      ;;

    resume)
      rm -f "$pause_file"
      "$mount_script"
      ;;

    status)
      echo "Automount:"
      if [[ -f "$pause_file" ]]; then
        echo "  paused"
      else
        echo "  active"
      fi

      echo
      echo "Mounted SMB volumes:"
      mount | grep -E "$HOME/Mounts/(dataLib|whisk)" || echo "  none"

      echo
      echo "Mount folders:"
      ls -ld "$HOME/Mounts/dataLib" "$HOME/Mounts/whisk" 2>/dev/null || true

      echo
      echo "Environment:"
      echo "  DATALIB=${DATALIB:-unset}"
      echo "  WHISK=${WHISK:-unset}"
      ;;

    logs)
      tail -n 100 "$log_file"
      ;;

    *)
      echo "Usage: smb-volumes {mount|unmount|remount|pause|resume|status|logs}"
      return 1
      ;;
  esac
}
