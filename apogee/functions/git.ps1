# apogee: git functions (pwsh)

function git_commit_push {
  param(
    [Parameter(Mandatory=$true)][string]$Message,
    [string]$Branch
  )

  $current = (git symbolic-ref --short HEAD 2>$null)
  if (-not $current) { $current = (git rev-parse --abbrev-ref HEAD 2>$null) }
  if (-not $current) { throw "Could not determine current branch." }

  if (-not $Branch) { $Branch = $current }

  git add . | Out-Null
  git commit -m $Message | Out-Null
  git push origin $Branch
}

function merge_branch {
  param(
    [Parameter(Mandatory=$true)][string]$Src,
    [Parameter(Mandatory=$true)][string]$Tgt
  )

  git fetch origin | Out-Null
  git checkout $Tgt | Out-Null
  git pull origin $Tgt | Out-Null
  git merge --no-ff $Src -m "Merge branch '$Src' into $Tgt" | Out-Null
  git push origin $Tgt
}

function git_blob_push {
  param(
    [Parameter(Mandatory=$true)][string]$File,
    [string]$Remote = "origin",
    [string]$Branch
  )

  if (-not (Test-Path -LiteralPath $File)) { throw "File not found: $File" }

  if (-not $Branch) { $Branch = (git rev-parse --abbrev-ref HEAD 2>$null) }
  if (-not $Branch) { throw "Could not determine current branch." }

  git push $Remote $Branch | Out-Null

  $remoteUrl = (git remote get-url $Remote)
  if (-not $remoteUrl) { throw "Could not resolve remote '$Remote'." }
  $remoteUrl = $remoteUrl -replace '\.git$',''

  if ($remoteUrl -match '^git@([^:]+):(.+)$') {
    $host = $Matches[1]
    $path = $Matches[2]
    $remoteUrl = "https://$host/$path"
  }

  $commit = (git rev-parse HEAD)
  if (-not $commit) { throw "Could not read HEAD commit." }

  $rel = (git ls-files --full-name $File 2>$null)
  if (-not $rel) {
    $root = (git rev-parse --show-toplevel)
    $rel = $File.Replace("$root\",'').Replace("$root/",'')
  }

  $url = "$remoteUrl/blob/$commit/$rel"

  "Blob URL:"
  "  $url"

  if (Get-Command Set-Clipboard -ErrorAction SilentlyContinue) {
    Set-Clipboard -Value $url
    "(copied to clipboard)"
  } else {
    "(Set-Clipboard not found; not copied)" | Write-Error
  }
}
