function __Apogee_Update-TmuxSeg {
  $sym = ""
  if ($env:TMUX) {
    $pwd = (Get-Location).Path
    if ($pwd -eq $HOME) { $env:STARSHIP_TMUX_SEG = $sym }
    else { $env:STARSHIP_TMUX_SEG = " $sym " }
  } else {
    Remove-Item Env:STARSHIP_TMUX_SEG -ErrorAction SilentlyContinue
  }
}

__Apogee_Update-TmuxSeg

# wrap prompt AFTER starship init (priority handles order)
if (-not $script:__apogee_tmux_seg_wrapped) {
  $script:__apogee_tmux_seg_wrapped = $true
  $oldPrompt = $function:prompt
  function prompt {
    __Apogee_Update-TmuxSeg
    & $oldPrompt
  }
}
