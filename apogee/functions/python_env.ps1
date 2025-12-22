# apogee/functions/python_env.ps1
# UV-first python env + pkg (PowerShell)

if (-not $env:APOGEE_UV_VENV_ROOT) { $env:APOGEE_UV_VENV_ROOT = "$HOME/.venvs" }
if (-not $env:APOGEE_UV_DEFAULT_PY) { $env:APOGEE_UV_DEFAULT_PY = "auto-houdini" }

function env_off {
  if (Get-Command conda -ErrorAction SilentlyContinue) {
    try {
      while ($env:CONDA_SHLVL -and [int]$env:CONDA_SHLVL -gt 0) { conda deactivate | Out-Null }
    } catch {}
  }
  if (Get-Command deactivate -ErrorAction SilentlyContinue) {
    try { deactivate | Out-Null } catch {}
  }
}

function __apogee_uv_project_root {
  try {
    if (Get-Command git -ErrorAction SilentlyContinue) {
      $root = (git -C . rev-parse --show-toplevel 2>$null)
      if ($root -and (Test-Path (Join-Path $root "pyproject.toml"))) { return $root }
    }
  } catch {}
  $d = (Get-Location).Path
  while ($d -and $d -ne [IO.Path]::GetPathRoot($d)) {
    if (Test-Path (Join-Path $d "pyproject.toml")) { return $d }
    $d = Split-Path $d -Parent
  }
  return $null
}

function __apogee_uv_env_for([string]$Root) {
  Join-Path $env:APOGEE_UV_VENV_ROOT (Split-Path $Root -Leaf)
}

function __apogee_uv_set_envvar {
  $root = __apogee_uv_project_root
  if ($root) { $env:UV_PROJECT_ENVIRONMENT = (__apogee_uv_env_for $root) }
  else { Remove-Item Env:\UV_PROJECT_ENVIRONMENT -ErrorAction SilentlyContinue | Out-Null }
}

function uv {
  __apogee_uv_set_envvar
  & (Get-Command uv -ErrorAction Stop) @args
}

function uvp {
  if ($env:UV_PROJECT_ENVIRONMENT) { $env:UV_PROJECT_ENVIRONMENT } else { "(unset)" }
}

function __apogee_uv_activate_in_project([string]$Root) {
  if (-not (Test-Path -Path $Root -PathType Container)) { throw "Project not found: $Root" }
  Set-Location $Root

  env_off

  if (-not (Get-Command uv -ErrorAction SilentlyContinue)) { throw "uv not found on PATH" }

  __apogee_uv_set_envvar
  $envroot = $env:UV_PROJECT_ENVIRONMENT
  if (-not $envroot) { $envroot = (__apogee_uv_env_for $Root); $env:UV_PROJECT_ENVIRONMENT = $envroot }

  $quiet = $env:APOGEE_UV_QUIET -eq "1"

  if (-not (Test-Path -Path (Join-Path $envroot "bin/python") -PathType Leaf)) {
    Remove-Item -Recurse -Force $envroot -ErrorAction SilentlyContinue | Out-Null
    if ($quiet) { uv venv --python $env:APOGEE_UV_DEFAULT_PY -q } else { uv venv --python $env:APOGEE_UV_DEFAULT_PY }
    if (Test-Path "uv.lock") { if ($quiet) { uv sync --frozen -q } else { uv sync --frozen } }
    else { if ($quiet) { uv lock -q; uv sync -q } else { uv lock; uv sync } }
  } else {
    if ($env:APOGEE_UV_SYNC_ON_ACTIVATE -eq "1" -or $env:APOGEE_UV_FORCE_SYNC -eq "1") {
      if (Test-Path "uv.lock") { if ($quiet) { uv sync --frozen -q } else { uv sync --frozen } }
      else { if ($quiet) { uv lock -q; uv sync -q } else { uv lock; uv sync } }
    }
  }

  # Activate.ps1 exists on posix venvs too
  $act1 = Join-Path $envroot "bin/Activate.ps1"
  $act2 = Join-Path $envroot "Scripts/Activate.ps1"
  if (Test-Path $act1) { . $act1 }
  elseif (Test-Path $act2) { . $act2 }
}

function __apogee_pkg_root {
  if ($env:PACKAGES) { return $env:PACKAGES }
  if ($env:MATRIX) { return (Join-Path $env:MATRIX "packages") }
  return (Join-Path $HOME "packages")
}

function __apogee_pkg_resolve([string]$Arg) {
  $root = __apogee_pkg_root
  if (Test-Path $Arg -PathType Container) { return (Resolve-Path $Arg).Path }
  $p = Join-Path $root $Arg
  if (Test-Path $p -PathType Container) { return $p }

  $dirs = Get-ChildItem -Path $root -Directory -ErrorAction SilentlyContinue
  foreach ($d in $dirs) {
    if ($d.Name.ToLowerInvariant() -eq $Arg.ToLowerInvariant()) { return $d.FullName }
  }
  return $null
}

function pkg {
  param(
    [Parameter(Mandatory=$true)][string]$Target,
    [switch]$CdOnly,
    [switch]$Hou,
    [string]$HouVersion
  )

  $root = __apogee_pkg_resolve $Target
  if (-not $root) { throw "pkg: not found → $Target" }

  Set-Location $root
  if ($CdOnly) { return }

  if ($Hou) {
    throw "pkg --hou is a placeholder in Apogee right now (Houdini wiring comes later)."
  }

  if (Test-Path (Join-Path $root "pyproject.toml")) {
    __apogee_uv_activate_in_project $root
  }
}
