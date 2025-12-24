function nukeUtils {
  param(
    [Parameter(Position=0)][string]$Cmd = "launch",
    [Parameter(ValueFromRemainingArguments=$true)][string[]]$Args
  )

  if (($env:APOGEE_HAS_NUKE -ne "1") -and -not (Get-Command nuke -ErrorAction SilentlyContinue)) {
    return
  }

  function Get-NukeUtilsRoot {
    if ($env:PACKAGES) {
      $p = Join-Path $env:PACKAGES "nukeUtils"
      if (Test-Path $p) { return $p }
    }
    if ($env:DROPBOX) {
      $p = Join-Path $env:DROPBOX "matrix/packages/nukeUtils"
      if (Test-Path $p) { return $p }
    }

    $p = Join-Path $HOME "Dropbox/matrix/packages/nukeUtils"
    if (Test-Path $p) { return $p }

    $p = Join-Path $HOME "Library/CloudStorage/Dropbox/matrix/packages/nukeUtils"
    if (Test-Path $p) { return $p }

    return $null
  }

  $root = Get-NukeUtilsRoot
  if (-not $root) {
    Write-Error "nukeUtils project not found. Expected PACKAGES/nukeUtils (or Dropbox fallback)."
    return
  }

  function Normalize-NukeVersion([string]$v) {
    if (-not $v) { return "" }
    return ($v -replace '^Nuke','')
  }

  function Ensure-NukeEnv {
    if (-not $env:NUKE_USER_DIR) { $env:NUKE_USER_DIR = (Join-Path $HOME ".nuke") }
    New-Item -ItemType Directory -Force -Path $env:NUKE_USER_DIR | Out-Null

    $plugins = Join-Path $root "plugins"
    if (Test-Path $plugins) {
      $sep = $IsWindows ? ";" : ":"
      $cur = $env:NUKE_PATH
      if (-not $cur) {
        $env:NUKE_PATH = $plugins
      } else {
        $parts = $cur -split [regex]::Escape($sep)
        if ($parts -notcontains $plugins) {
          $env:NUKE_PATH = "$plugins$sep$cur"
        }
      }
    }
  }

  function Activate-Project {
    if (-not (Test-Path $root)) { throw "Project not found: $root" }
    Set-Location $root

    # Optional uv integration if your python_env.ps1 defines it
    if (Get-Command _uv_activate_in_project -ErrorAction SilentlyContinue) {
      _uv_activate_in_project $root
    }
  }

  function Launch-Nuke {
    $edition = $env:NUKE_EDITION
    if (-not $edition) { $edition = "Nuke" }

    $vin = $env:NUKE_VERSION
    if (-not $vin) { $vin = $env:APOGEE_NUKE_VERSION }
    if (-not $vin) { $vin = $env:APOGEE_NUKE_DEFAULT }

    $v = Normalize-NukeVersion $vin

    if (Get-Command nuke -ErrorAction SilentlyContinue) {
      & nuke @Args
      return
    }

    if ($IsMacOS -and (Get-Command open -ErrorAction SilentlyContinue)) {
      $app = $edition
      if ($v) { $app = "$edition$v" }
      & open -a $app --args @Args 2>$null
      if ($LASTEXITCODE -ne 0) { & open -a $app 2>$null }
      return
    }

    Write-Error "No 'nuke' command found (PATH) and no macOS app launch path available."
  }

  switch ($Cmd) {
    "-e" { Activate-Project; Ensure-NukeEnv; Write-Output "Nuke env ready. root=$root" }
    "env" { Activate-Project; Ensure-NukeEnv; Write-Output "Nuke env ready. root=$root" }
    "launch" { try { Activate-Project | Out-Null } catch {} ; Ensure-NukeEnv; Launch-Nuke }
    "" { try { Activate-Project | Out-Null } catch {} ; Ensure-NukeEnv; Launch-Nuke }
    default { Write-Error "Usage: nukeUtils [launch] | nukeUtils -e" }
  }
}
