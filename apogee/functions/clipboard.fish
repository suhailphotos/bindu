function pbcopy {
  $inputText = [Console]::In.ReadToEnd()

  if (Get-Command pbcopy -ErrorAction SilentlyContinue) {
    # On mac, pbcopy is a real command; call it without recursion:
    $p = Start-Process -FilePath (Get-Command pbcopy).Source -NoNewWindow -PassThru -RedirectStandardInput "pipe"
    $p.StandardInput.Write($inputText)
    $p.StandardInput.Close()
    $p.WaitForExit()
    return
  }

  if (Get-Command Set-Clipboard -ErrorAction SilentlyContinue) {
    $inputText | Set-Clipboard
    return
  }

  if (Get-Command clip.exe -ErrorAction SilentlyContinue) {
    $inputText | & clip.exe
    return
  }

  throw "pbcopy: no clipboard backend available"
}

function pbpaste {
  if (Get-Command pbpaste -ErrorAction SilentlyContinue) {
    & (Get-Command pbpaste).Source
    return
  }

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
