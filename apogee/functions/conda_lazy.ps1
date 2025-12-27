function Initialize-ApogeeCondaOnce {
  if ($script:APOGEE_CONDA_INITIALIZED) { return $true }

  $candidates = @(
    (Join-Path $HOME "anaconda3\Scripts\conda.exe"),
    (Join-Path $HOME "miniconda3\Scripts\conda.exe")
  )

  $conda = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
  if (-not $conda) {
    $conda = (Get-Command conda -ErrorAction SilentlyContinue)?.Source
  }
  if (-not $conda) { return $false }

  $hook = & $conda "shell.powershell" "hook" 2>$null
  if (-not $hook) { return $false }

  Invoke-Expression $hook
  $script:APOGEE_CONDA_INITIALIZED = $true
  return $true
}

function conda {
  if (-not (Initialize-ApogeeCondaOnce)) {
    Write-Error "conda: failed to initialize conda"
    return
  }

  # After init, the hook defines/replaces `conda`, so this calls the real one.
  conda @Args
}

function mamba {
  if (-not (Initialize-ApogeeCondaOnce)) {
    Write-Error "mamba: failed to initialize conda"
    return
  }
  & (Get-Command mamba -ErrorAction Stop).Source @Args
}
