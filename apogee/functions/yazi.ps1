function y {
  $tmp = New-TemporaryFile
  & yazi --cwd-file $tmp.FullName @Args
  if (Test-Path $tmp.FullName) {
    $newcwd = Get-Content $tmp.FullName -ErrorAction SilentlyContinue
    if ($newcwd -and ($newcwd -ne $PWD.Path)) { Set-Location $newcwd }
    Remove-Item $tmp.FullName -ErrorAction SilentlyContinue
  }
}
Set-Alias yy yazi
function yya { & yazi --chooser=append @Args }
