# apogee/functions/houdini.ps1

if ($env:APOGEE_HAS_HOUDINI -ne "1") {
  function hou { Write-Host "Houdini not detected on this host."; return }
  return
}

function Get-HouPlatform {
  if ($IsMacOS) { return "mac" }
  if ($IsLinux) {
    try {
      $v = Get-Content /proc/version -ErrorAction SilentlyContinue
      if ($v -match "microsoft") { return "wsl" }
    } catch {}
    return "linux"
  }
  return "other"
}

function Get-HouVersions {
  $plat = Get-HouPlatform
  if ($plat -eq "mac") {
    $dirs = Get-ChildItem "/Applications/Houdini" -Directory -ErrorAction SilentlyContinue |
      Where-Object { $_.Name -like "Houdini*" } |
      ForEach-Object { $_.Name -replace "^Houdini", "" }
  } else {
    $dirs = Get-ChildItem "/" -Directory -ErrorAction SilentlyContinue |
      Where-Object { $_.Name -like "hfs*" } |
      ForEach-Object { $_.Name -replace "^hfs", "" }
  }

  $dirs |
    Where-Object { $_ -match '^\d+\.\d+\.\d+$' } |
    Sort-Object { [version]$_ } -Descending
}

function Resolve-HouVersion([string]$Want) {
  if ($Want -and $Want -ne "latest") { return $Want }
  if ($env:APOGEE_HOUDINI_VERSION) { return $env:APOGEE_HOUDINI_VERSION }
  return (Get-HouVersions | Select-Object -First 1)
}

function Resolve-HouPaths([string]$Ver) {
  $plat = Get-HouPlatform
  if ($plat -eq "mac") {
    $root = "/Applications/Houdini/Houdini$Ver"
    $res  = "$root/Frameworks/Houdini.framework/Versions/Current/Resources"
    $py   = "$root/Frameworks/Houdini.framework/Versions/Current/Resources/Frameworks/Python.framework/Versions/Current/bin/python3"
    $hfs  = "$root/Frameworks/Houdini.framework/Versions/Current"
    if (!(Test-Path $py) -or !(Test-Path $res)) { return $null }
    return @{ RES=$res; PYBIN=$py; HFS=$hfs }
  } else {
    $hfs = "/opt/hfs$Ver"
    if (!(Test-Path $hfs)) { return $null }
    $candidates = @("$hfs/bin/python3.11", "$hfs/bin/python3.10", "$hfs/bin/python3")
    $py = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
    if (!$py) { return $null }
    return @{ RES=$hfs; PYBIN=$py; HFS=$hfs }
  }
}

function Get-HouPrefDir([string]$Ver) {
  $mm = $Ver -replace '\.\d+$',''
  switch (Get-HouPlatform) {
    "mac" { return "$HOME/Library/Preferences/houdini/$mm" }
    "wsl" { return "$HOME/Documents/houdini$mm" }
    default { return "$HOME/houdini$mm" }
  }
}

function Get-VenvSitePackages([string]$VenvRoot) {
  $py = "$VenvRoot/bin/python"
  if (!(Test-Path $py)) { return $null }
  return & $py -c "import sysconfig; print(sysconfig.get_paths().get('purelib',''))"
}

function hou {
  param(
    [string]$Cmd = "help",
    [string]$Ver = ""
  )

  if ($Cmd -eq "help") {
    Write-Host "hou — SideFX/Houdini helpers"
    Write-Host "Usage: hou versions | python|prefs|use|pkgshim|patch|doctor [VER|latest]"
    return
  }

  if ($Cmd -eq "versions") {
    Get-HouVersions
    return
  }

  $v = Resolve-HouVersion $Ver
  if (!$v) { Write-Host "Couldn’t resolve Houdini version."; return }

  $p = Resolve-HouPaths $v
  if (!$p) { Write-Host "Couldn’t resolve paths for $v"; return }

  $RES = $p.RES; $HFS = $p.HFS; $PYBIN = $p.PYBIN

  switch ($Cmd) {
    "python" { Write-Output $PYBIN }
    "prefs" {
      $pref = Get-HouPrefDir $v
      $env:HOUDINI_USER_PREF_DIR = $pref
      New-Item -ItemType Directory -Force -Path $pref | Out-Null
      Write-Host "HOUDINI_USER_PREF_DIR=$pref"
    }
    "use" {
      $proj = Get-Location
      # best-effort: walk up until pyproject.toml
      while ($proj -and !(Test-Path (Join-Path $proj "pyproject.toml"))) {
        $parent = Split-Path $proj -Parent
        if ($parent -eq $proj) { $proj = $null } else { $proj = $parent }
      }
      if (!$proj) { Write-Host "Not inside a project (pyproject.toml not found)."; return }

      Set-Location $proj
      $name = Split-Path $proj -Leaf
      $venvBase = if ($env:APOGEE_UV_VENV_ROOT) { $env:APOGEE_UV_VENV_ROOT } else { "$HOME/.venvs" }
      $envroot = Join-Path $venvBase $name
      $env:UV_PROJECT_ENVIRONMENT = $envroot

      $q = if ($env:APOGEE_UV_QUIET -eq "1") { "-q" } else { "" }

      if (Test-Path "$envroot/bin/python") {
        $cur = & "$envroot/bin/python" -c "import sys; print(sys.executable)"
        if ($cur -ne $PYBIN) {
          Write-Host "Recreating env with SideFX Python…"
          Remove-Item -Recurse -Force $envroot -ErrorAction SilentlyContinue
          & uv venv --python $PYBIN $q | Out-Null
          if (Test-Path "uv.lock") { & uv sync --frozen $q | Out-Null } else { & uv lock $q | Out-Null; & uv sync $q | Out-Null }
        }
      } else {
        & uv venv --python $PYBIN $q | Out-Null
        if (Test-Path "uv.lock") { & uv sync --frozen $q | Out-Null } else { & uv lock $q | Out-Null; & uv sync $q | Out-Null }
      }

      # PowerShell venv activation on POSIX
      $act = "$envroot/bin/Activate.ps1"
      if (Test-Path $act) { . $act }
      Write-Host "hou use: interpreter → $PYBIN"
    }
    "patch" {
      $proj = Get-Location
      while ($proj -and !(Test-Path (Join-Path $proj "pyproject.toml"))) {
        $parent = Split-Path $proj -Parent
        if ($parent -eq $proj) { $proj = $null } else { $proj = $parent }
      }
      if (!$proj) { Write-Host "Not inside a project (pyproject.toml not found)."; return }

      $name = Split-Path $proj -Leaf
      $venvBase = if ($env:APOGEE_UV_VENV_ROOT) { $env:APOGEE_UV_VENV_ROOT } else { "$HOME/.venvs" }
      $envroot = Join-Path $venvBase $name

      $pref = Get-HouPrefDir $v
      $env:HOUDINI_USER_PREF_DIR = $pref
      New-Item -ItemType Directory -Force -Path $pref | Out-Null

      $site = Get-VenvSitePackages $envroot
      if (!$site) { Write-Host "No env yet; run 'hou use' first."; return }

      $envfile = Join-Path $pref "houdini.env"
      if (!(Test-Path $envfile)) { New-Item -ItemType File -Force -Path $envfile | Out-Null }
      $txt = Get-Content $envfile -ErrorAction SilentlyContinue
      if ($txt -notcontains "PYTHONPATH=`"`$PYTHONPATH:$site`"") {
        Add-Content -Path $envfile -Value "PYTHONPATH=`"`$PYTHONPATH:$site`""
        Write-Host "→ Added site-packages to $envfile"
      } else {
        Write-Host "→ Site-packages already present in $envfile"
      }
    }
    "pkgshim" {
      $proj = Get-Location
      while ($proj -and !(Test-Path (Join-Path $proj "pyproject.toml"))) {
        $parent = Split-Path $proj -Parent
        if ($parent -eq $proj) { $proj = $null } else { $proj = $parent }
      }
      if (!$proj) { Write-Host "Not inside a project (pyproject.toml not found)."; return }

      $name = Split-Path $proj -Leaf
      $venvBase = if ($env:APOGEE_UV_VENV_ROOT) { $env:APOGEE_UV_VENV_ROOT } else { "$HOME/.venvs" }
      $envroot = Join-Path $venvBase $name

      $pref = Get-HouPrefDir $v
      $env:HOUDINI_USER_PREF_DIR = $pref
      $pkgdir = Join-Path $pref "packages"
      New-Item -ItemType Directory -Force -Path $pkgdir | Out-Null

      $site = Get-VenvSitePackages $envroot
      if (!$site) { Write-Host "No env yet; run 'hou use' first."; return }

      $jsonfile = Join-Path $pkgdir "98_uv_site.json"
      @"
{
  "enable": true,
  "load_package_once": true,
  "env": [{ "PYTHONPATH": "\${PYTHONPATH}:$site" }]
}
"@ | Set-Content -Path $jsonfile
      Write-Host "→ Wrote dev shim: $jsonfile"
      Write-Host "Dev package shim ready (Houdini will pick it up next launch)."
    }
    "doctor" {
      Write-Host "Resolved:"
      Write-Host "  Version : $v"
      Write-Host "  RES     : $RES"
      Write-Host "  HFS     : $HFS"
      Write-Host "  PYBIN   : $PYBIN"
    }
    default {
      Write-Host "Unknown command: $Cmd"
      Write-Host "Usage: hou versions | python|prefs|use|pkgshim|patch|doctor [VER|latest]"
    }
  }
}
