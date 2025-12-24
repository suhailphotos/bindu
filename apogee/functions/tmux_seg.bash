_apogee_tmux_seg_update() {
  local sym=''
  if [[ -n "${TMUX-}" ]]; then
    if [[ "$PWD" == "$HOME" ]]; then
      export STARSHIP_TMUX_SEG="${sym}"
    else
      export STARSHIP_TMUX_SEG=" ${sym} "
    fi
  else
    unset STARSHIP_TMUX_SEG
  fi
}

# run once now
_apogee_tmux_seg_update

# prepend to PROMPT_COMMAND (don’t clobber existing)
case ";${PROMPT_COMMAND-};" in
  *";_apogee_tmux_seg_update;"*) ;;
  *) PROMPT_COMMAND="_apogee_tmux_seg_update${PROMPT_COMMAND:+; $PROMPT_COMMAND}" ;;
esac
