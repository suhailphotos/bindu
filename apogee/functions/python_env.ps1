# apogee/functions/python_env.ps1
# UV-first python env + pkg (PowerShell)
#
# Host-mimic policy:
# - Do NOT set UV_PYTHON_INSTALL_DIR here.
# - Let uv use its default per-user layout:
#     ~/.local/share/uv/python
#     ~/.local/share/uv/tools
#     ~/.local/share/uv/bin
# - Ensure requested Python exists on-demand (uv python install <ver>), idempotent.
# - Keep UV_PROJECT_ENVIRONMENT updated automatically (prompt hook).
# - Starship env name comes from PROMPT_PY_ENV_NAME (updated each prompt).

# -----------------------------
# Defaults (only if not set)
# -----------------------------
if (-not $env:APOGEE_UV_VENV_ROOT)        { $env:APOGEE_UV_VENV_ROOT = Join-Path $HOME ".venvs" }
if (-not $env:APOGEE_UV_DEFAULT_PY)       { $env:APOGEE_UV_DEFAULT_PY = "auto-houdini" }
if (-not $env:APOGEE_UV_QUIET)            { $env:APOGEE_UV_QUIET = "0" }
if (-not $env:APOGEE_UV_SYNC_ON_ACTIVATE) { $env:APOGEE_UV_SYNC_ON_ACTIVATE = "0" }
if (-not $env:APOGEE_UV_FORCE_SYNC)       { $env:APOGEE_UV_FORCE_SYNC = "0" }

# -----------------------------
# Deactivate helpers
# -----------------------------
function _apogee_py_deactivate {
  # Conda (best-effort)
  if (Get-Command conda -ErrorAction SilentlyContinue) {
    $shlvl = 0
    if ($env:CONDA_SHLVL -and [int]::TryParse($env:CONDA_SHLVL, [ref]$shlvl) -and $shlvl -gt 0) {
      while ($shlvl -gt 0) {
        try { conda deactivate *> $null } catch { break }
        $shlvl--
      }
    }
  }

  # venv (PowerShell activate defines 'deactivate' function)
  if ($env:VIRTUAL_ENV) {
    $deact = Get-Command deactivate -ErrorAction SilentlyContinue
    if ($deact -and $deact.CommandType -eq 'Function') {
      try { deactivate *> $null } catch { }
    }
  }
}

function env_off { _apogee_py_deactivate }

# -----------------------------
# Project root detection
# -----------------------------
function _apogee_uv_project_root {
  # Prefer git root if it contains pyproject.toml
  if (Get-Command git -ErrorAction SilentlyContinue) {
    try {
      $root = (git -C . rev-parse --show-toplevel 2>$null).Trim()
      if ($root -and (Test-Path (Join-Path $root "pyproject.toml"))) {
        return $root
      }
    } catch { }
  }

  # Walk up from PWD
  $d = (Get-Location).Path
  while ($d -and $d -ne [System.IO.Path]::GetPathRoot($d)) {
    if (Test-Path (Join-Path $d "pyproject.toml")) { return $d }
    $parent = Split-Path -Parent $d
    if (-not $parent -or $parent -eq $d) { break }
    $d = $parent
  }

  if ($d -and (Test-Path (Join-Path $d "pyproject.toml"))) { return $d }
  return $null
}

function _apogee_uv_env_for([string]$root) {
  Join-Path $env:APOGEE_UV_VENV_ROOT ([System.IO.Path]::GetFileName($root))
}

function _apogee_uv_set_envvar {
  $root = _apogee_uv_project_root
  if (-not $root) {
    Remove-Item Env:UV_PROJECT_ENVIRONMENT -ErrorAction SilentlyContinue
    return
  }
  $env:UV_PROJECT_ENVIRONMENT = _apogee_uv_env_for $root
}

# -----------------------------
# uv wrapper (keeps UV_PROJECT_ENVIRONMENT correct)
# -----------------------------
if (Get-Command uv -ErrorAction SilentlyContinue) {
  # Avoid redefining if user already did
  if (-not (Get-Command uv -ErrorAction SilentlyContinue | Where-Object { $_.CommandType -eq 'Function' })) {
    function uv { _apogee_uv_set_envvar; & (Get-Command uv -CommandType Application).Source @args }
  } else {
    # If they already have a function named uv, don’t stomp it.
    # They can still call _apogee_uv_set_envvar manually if they want.
  }
}

function uvp {
  if ($env:UV_PROJECT_ENVIRONMENT) { $env:UV_PROJECT_ENVIRONMENT } else { "(unset)" }
}

# -----------------------------
# Version selection helpers
# -----------------------------
function _apogee_py_mm_to_num([string]$mm) {
  $parts = $mm.Split('.', 2)
  $major = [int]$parts[0]
  $minor = [int]$parts[1]
  return ($major * 100 + $minor)
}

function _apogee_pyproject_requires_python([string]$root) {
  $f = Join-Path $root "pyproject.toml"
  if (-not (Test-Path $f)) { return $null }

  foreach ($line in (Get-Content -LiteralPath $f -ErrorAction SilentlyContinue)) {
    if ($line -match '^\s*requires-python\s*=\s*"(.*)"\s*$') {
      return $Matches[1]
    }
  }
  return $null
}

function _apogee_requires_min_mm([string]$spec) {
  if (-not $spec) { return $null }
  $m = [regex]::Match($spec, '>=\s*([0-9]+)\.([0-9]+)')
  if ($m.Success) { return "$($m.Groups[1].Value).$($m.Groups[2].Value)" }
  return $null
}

function _apogee_houdini_python_mm {
  if (Get-Command hython -ErrorAction SilentlyContinue) {
    try {
      $mm = (& hython -c 'import sys; print(f"{sys.version_info[0]}.{sys.version_info[1]}")' 2>$null).Trim()
      if ($mm) { return $mm }
    } catch { }
  }

  if ($env:APOGEE_HOUDINI_DETECT_PATH) {
    $hython = Join-Path $env:APOGEE_HOUDINI_DETECT_PATH "bin/hython"
    if (Test-Path $hython) {
      try {
        $mm = (& $hython -c 'import sys; print(f"{sys.version_info[0]}.{sys.version_info[1]}")' 2>$null).Trim()
        if ($mm) { return $mm }
      } catch { }
    }
  }

  return $null
}

function _apogee_uv_default_python_spec {
  $mode = $env:APOGEE_UV_DEFAULT_PY
  if ($mode -and $mode -ne "auto-houdini") { return $mode }

  $hou = _apogee_houdini_python_mm
  if ($hou) { return $hou }

  return "3"
}

function _apogee_uv_pick_python_for_project([string]$root) {
  $pyver = Join-Path $root ".python-version"
  if (Test-Path $pyver) {
    try {
      return ((Get-Content -LiteralPath $pyver -TotalCount 1).Trim().Split()[0])
    } catch { }
  }

  $req    = _apogee_pyproject_requires_python $root
  $min_mm = _apogee_requires_min_mm $req

  $def    = _apogee_uv_default_python_spec
  $def_mm = $def

  if ($min_mm) {
    if ($def_mm -match '^[0-9]+\.[0-9]+$') {
      if ((_apogee_py_mm_to_num $def_mm) -ge (_apogee_py_mm_to_num $min_mm)) {
        return $def_mm
      }
    }
    return $min_mm
  }

  return $def
}

function _apogee_uv_pin_python_if_missing([string]$root, [string]$py) {
  if (-not ($py -match '^[0-9]+(\.[0-9]+){0,2}$')) { return }
  if (Test-Path (Join-Path $root ".python-version")) { return }
  try {
    $null = [IO.File]::OpenWrite((Join-Path $root ".apogee_write_test")); Remove-Item (Join-Path $root ".apogee_write_test") -Force -ErrorAction SilentlyContinue
  } catch { return }

  if (Get-Command uv -ErrorAction SilentlyContinue) {
    try { & uv python pin $py *> $null } catch { }
  }
}

function _apogee_uv_ensure_python_installed([string]$py) {
  if (-not ($py -match '^[0-9]+(\.[0-9]+){0,2}$')) { return $true }
  if (-not (Get-Command uv -ErrorAction SilentlyContinue)) { return $true }

  try {
    & uv python install $py *> $null
    return $true
  } catch {
    try { & uv python install $py | Out-Null; return $true } catch { return $false }
  }
}

# -----------------------------
# Activation
# -----------------------------
function _apogee_uv_activate_in_project([string]$root) {
  if (-not (Test-Path $root -PathType Container)) { Write-Error "Project not found: $root"; return $false }
  Set-Location $root

  _apogee_py_deactivate
  if (-not (Get-Command uv -ErrorAction SilentlyContinue)) { Write-Error "uv not found on PATH"; return $false }

  $envroot = if ($env:UV_PROJECT_ENVIRONMENT) { $env:UV_PROJECT_ENVIRONMENT } else { Join-Path $env:APOGEE_UV_VENV_ROOT ([IO.Path]::GetFileName($root)) }
  $env:UV_PROJECT_ENVIRONMENT = $envroot

  $want = _apogee_uv_pick_python_for_project $root
  _apogee_uv_pin_python_if_missing $root $want

  if (-not (_apogee_uv_ensure_python_installed $want)) {
    Write-Error "uv: failed to install/ensure Python '$want'"
    return $false
  }

  $q = if ($env:APOGEE_UV_QUIET -eq "1") { "-q" } else { $null }

  $pythonExe = Join-Path $envroot "Scripts/python.exe"
  $activate  = Join-Path $envroot "Scripts/Activate.ps1"

  if (-not (Test-Path $pythonExe)) {
    Remove-Item $envroot -Recurse -Force -ErrorAction SilentlyContinue

    # Rely on UV_PROJECT_ENVIRONMENT; do NOT pass an env path arg
    if ($q) { & uv venv --python $want $q | Out-Null } else { & uv venv --python $want | Out-Null }
    if ($LASTEXITCODE -ne 0) { return $false }

    if (Test-Path (Join-Path $root "uv.lock")) {
      if ($q) { & uv sync --frozen $q | Out-Null } else { & uv sync --frozen | Out-Null }
      if ($LASTEXITCODE -ne 0) { return $false }
    } else {
      if ($q) { & uv lock $q | Out-Null } else { & uv lock | Out-Null }
      if ($LASTEXITCODE -ne 0) { return $false }
      if ($q) { & uv sync $q | Out-Null } else { & uv sync | Out-Null }
      if ($LASTEXITCODE -ne 0) { return $false }
    }
  } else {
    if ($env:APOGEE_UV_SYNC_ON_ACTIVATE -eq "1" -or $env:APOGEE_UV_FORCE_SYNC -eq "1") {
      if (Test-Path (Join-Path $root "uv.lock")) {
        if ($q) { & uv sync --frozen $q | Out-Null } else { & uv sync --frozen | Out-Null }
        if ($LASTEXITCODE -ne 0) { return $false }
      } else {
        if ($q) { & uv lock $q | Out-Null } else { & uv lock | Out-Null }
        if ($LASTEXITCODE -ne 0) { return $false }
        if ($q) { & uv sync $q | Out-Null } else { & uv sync | Out-Null }
        if ($LASTEXITCODE -ne 0) { return $false }
      }
    }
  }

  if (Test-Path $activate) {
    . $activate
    return $true
  }

  Write-Error "Activate.ps1 not found in $envroot"
  return $false
}

# -----------------------------
# Starship env name
# -----------------------------
function _apogee_set_prompt_py_env_name {
  if ($env:VIRTUAL_ENV) {
    $env:PROMPT_PY_ENV_NAME = Split-Path -Leaf $env:VIRTUAL_ENV
    return
  }
  if ($env:CONDA_DEFAULT_ENV) {
    $env:PROMPT_PY_ENV_NAME = $env:CONDA_DEFAULT_ENV
    return
  }
  Remove-Item Env:PROMPT_PY_ENV_NAME -ErrorAction SilentlyContinue
}

# -----------------------------
# Prompt hook (without breaking user prompt)
# -----------------------------
if (-not $global:__apogee_old_prompt) {
  $global:__apogee_old_prompt = $function:prompt
}

function prompt {
  try {
    _apogee_uv_set_envvar
    _apogee_set_prompt_py_env_name
  } catch { }

  if ($global:__apogee_old_prompt) {
    & $global:__apogee_old_prompt
  } else {
    "PS $($executionContext.SessionState.Path.CurrentLocation)$('>' * ($nestedPromptLevel + 1)) "
  }
}

# -----------------------------
# pkg
# -----------------------------
function _apogee_pkg_root {
  if ($env:PACKAGES) { return $env:PACKAGES }
  if ($env:MATRIX)   { return (Join-Path $env:MATRIX "packages") }
  return (Join-Path $HOME "packages")
}

function _apogee_pkg_resolve([string]$arg) {
  $root = _apogee_pkg_root

  if (Test-Path $arg -PathType Container) {
    return (Resolve-Path $arg).Path
  }

  $p = Join-Path $root $arg
  if (Test-Path $p -PathType Container) { return $p }

  # case-insensitive scan
  if (Test-Path $root -PathType Container) {
    foreach ($d in Get-ChildItem -LiteralPath $root -Directory -ErrorAction SilentlyContinue) {
      if ($d.Name.ToLowerInvariant() -eq $arg.ToLowerInvariant()) {
        return $d.FullName
      }
    }
  }

  return $null
}

function pkg {
  param(
    [Parameter(Position=0, Mandatory=$true)]
    [string]$NameOrPath,

    [switch]$CdOnly,

    [switch]$Hou,
    [string]$HouVersion
  )

  $root = _apogee_pkg_resolve $NameOrPath
  if (-not $root) { Write-Error "pkg: not found → $NameOrPath"; return }

  Set-Location $root

  if ($CdOnly) { return }

  if ($Hou) {
    Write-Error "pkg --hou is a placeholder in Apogee right now (Houdini wiring comes later)."
    return
  }

  if (Test-Path (Join-Path $root "pyproject.toml")) {
    if ($env:APOGEE_PLATFORM -eq "linux" -and $env:APOGEE_USE_CONDA -eq "1" -and (Get-Command conda -ErrorAction SilentlyContinue)) {
      _apogee_py_deactivate
      try { conda activate (Split-Path -Leaf $root) } catch { throw }
    } else {
      $ok = _apogee_uv_activate_in_project $root
      if (-not $ok) { throw "pkg: failed to activate uv env" }
    }
  }
}
