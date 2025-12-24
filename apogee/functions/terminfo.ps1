function Push-Terminfo {
  param(
    [Parameter(Mandatory=$true)][string]$HostSpec,
    [string]$Term = $(if ($env:TERM) { $env:TERM } else { "xterm-256color" })
  )

  if (-not (Get-Command infocmp -ErrorAction SilentlyContinue)) { throw "Push-Terminfo: infocmp not found" }
  if (-not (Get-Command ssh -ErrorAction SilentlyContinue))     { throw "Push-Terminfo: ssh not found" }

  # tic is on the remote; local check is optional, but we can still warn if missing locally.
  if (-not (infocmp -x $Term 2>$null)) { throw "Local system doesn’t know term '$Term'." }

  $data = & infocmp -x $Term
  $data | & ssh $HostSpec 'mkdir -p ~/.terminfo && tic -x -o ~/.terminfo /dev/stdin'
}

function Terminfo-Ok {
  param(
    [Parameter(Mandatory=$true)][string]$HostSpec,
    [string]$Term = $(if ($env:TERM) { $env:TERM } else { "xterm-256color" })
  )

  & ssh $HostSpec "infocmp -x $Term >/dev/null 2>&1 && echo '$Term: OK' || echo '$Term: MISSING'"
}
