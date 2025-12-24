# If pbcopy/pbpaste already exist (mac), don't override.
if (Get-Command pbcopy -ErrorAction SilentlyContinue -CommandType Application) { return }
if (Get-Command pbpaste -ErrorAction SilentlyContinue -CommandType Application) { return }

function pbcopy {
  $text = [Console]::In.ReadToEnd()

  if (Get-Command Set-Clipboard -ErrorAction SilentlyContinue) {
    $text | Set-Clipboard
    return
  }

  if (Get-Command clip.exe -ErrorAction SilentlyContinue) {
    $text | & clip.exe
    return
  }

  throw "pbcopy: no clipboard backend available"
}

function pbpaste {
  if (Get-Command Get-Clipboard -ErrorAction SilentlyContinue) {
    Get-Clipboard
    return
  }

  if (Get-Command powershell.exe -ErrorAction SilentlyContinue) {
    & powershell.exe -NoProfile -Command 'Get-Clipboard' 2>$null
    return
  }

  throw "pbpaste: no clipboard backend available"
}
