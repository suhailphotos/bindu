# apogee: git functions (zsh/bash)

_apogee_copy() {
  # usage: _apogee_copy "text"
  if command -v pbcopy >/dev/null 2>&1; then
    printf '%s' "$1" | pbcopy
    return 0
  fi
  if command -v wl-copy >/dev/null 2>&1; then
    printf '%s' "$1" | wl-copy
    return 0
  fi
  if command -v xclip >/dev/null 2>&1; then
    printf '%s' "$1" | xclip -selection clipboard
    return 0
  fi
  return 1
}

git_commit_push() {
  [ -z "${1:-}" ] && { echo "Usage: git_commit_push <message> [branch]" >&2; return 1; }

  local current_branch
  current_branch="$(
    command git symbolic-ref --short HEAD 2>/dev/null \
      || command git rev-parse --abbrev-ref HEAD 2>/dev/null
  )"

  [ -z "$current_branch" ] && { echo "Could not determine current branch." >&2; return 1; }

  local branch="${2:-$current_branch}"

  command git add . || return 1
  command git commit -m "$1" || return 1
  command git push origin "$branch"
}

merge_branch() {
  [ -z "${1:-}" ] || [ -z "${2:-}" ] && { echo "Usage: merge_branch <src> <tgt>" >&2; return 1; }

  command git fetch origin || return 1
  command git checkout "$2" || return 1
  command git pull origin "$2" || return 1
  command git merge --no-ff "$1" -m "Merge branch '$1' into $2" || return 1
  command git push origin "$2"
}

git_blob_push() {
  [ -z "${1:-}" ] && { echo "Usage: git_blob_push <path/to/file> [remote] [branch]" >&2; return 1; }

  local file="$1"
  local remote="${2:-origin}"
  local branch="${3:-$(command git rev-parse --abbrev-ref HEAD 2>/dev/null)}"

  [ -z "$branch" ] && { echo "Could not determine current branch." >&2; return 1; }
  [ ! -e "$file" ] && { echo "File not found: $file" >&2; return 1; }

  command git push "$remote" "$branch" || return 1

  local remote_url
  remote_url="$(command git remote get-url "$remote")" || return 1
  remote_url="${remote_url%.git}"

  case "$remote_url" in
    git@*:*/*)
      # git@github.com:user/repo -> https://github.com/user/repo
      local hostpath="${remote_url#git@}"     # github.com:user/repo
      local host="${hostpath%%:*}"            # github.com
      local path="${hostpath#*:}"             # user/repo
      remote_url="https://$host/$path"
      ;;
  esac

  local commit
  commit="$(command git rev-parse HEAD)" || return 1

  local rel root
  rel="$(command git ls-files --full-name "$file" 2>/dev/null || true)"
  if [ -z "$rel" ]; then
    root="$(command git rev-parse --show-toplevel)" || return 1
    rel="${file#$root/}"
  fi

  local url="${remote_url}/blob/${commit}/${rel}"

  echo "Blob URL:"
  echo "  $url"

  if _apogee_copy "$url"; then
    echo "(copied to clipboard)"
  else
    echo "(clipboard tool not found; not copied)" >&2
  fi
}
