# apogee: eza helpers (pwsh)
if (-not (Get-Command eza -ErrorAction SilentlyContinue)) { return }

if (-not $env:APOGEE_LS_ICONS)     { $env:APOGEE_LS_ICONS = "0" }
if (-not $env:APOGEE_DOTFILES_SGR) { $env:APOGEE_DOTFILES_SGR = "90" }
if (-not $env:EZA_CONFIG_DIR)      { $env:EZA_CONFIG_DIR = "$HOME/.config/eza" }

function Get-ApogeeEzaCommonFlags {
  $flags = @("--group-directories-first")
  if ($env:APOGEE_LS_ICONS -eq "1") { $flags += "--icons=auto" }
  return $flags
}

function Invoke-ApogeeEzaWithColors {
  param([Parameter(ValueFromRemainingArguments=$true)][string[]]$Args)

  $old = $env:EZA_COLORS
  $prefix = ".*=$($env:APOGEE_DOTFILES_SGR)"
  if ([string]::IsNullOrEmpty($old)) { $env:EZA_COLORS = $prefix }
  else { $env:EZA_COLORS = "$prefix`:$old" }

  try { eza @Args }
  finally { $env:EZA_COLORS = $old }
}

function ls   { Invoke-ApogeeEzaWithColors (Get-ApogeeEzaCommonFlags) @Args }
function la   { Invoke-ApogeeEzaWithColors "-la" (Get-ApogeeEzaCommonFlags) @Args }
function ll   { Invoke-ApogeeEzaWithColors "-lah" (Get-ApogeeEzaCommonFlags) @Args }
function tree { Invoke-ApogeeEzaWithColors "--tree" (Get-ApogeeEzaCommonFlags) @Args }
