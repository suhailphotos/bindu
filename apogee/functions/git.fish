# apogee: git functions (fish)

function __apogee_copy --argument-names text
    if type -q pbcopy
        printf '%s' $text | pbcopy
        return 0
    end
    if type -q wl-copy
        printf '%s' $text | wl-copy
        return 0
    end
    if type -q xclip
        printf '%s' $text | xclip -selection clipboard
        return 0
    end
    return 1
end

function git_commit_push
    if test (count $argv) -lt 1
        echo "Usage: git_commit_push <message> [branch]" 1>&2
        return 1
    end

    set -l msg $argv[1]

    set -l current_branch (command git symbolic-ref --short HEAD 2>/dev/null; or command git rev-parse --abbrev-ref HEAD 2>/dev/null)
    if test -z "$current_branch"
        echo "Could not determine current branch." 1>&2
        return 1
    end

    set -l branch $current_branch
    if test (count $argv) -ge 2
        set branch $argv[2]
    end

    command git add .; or return 1
    command git commit -m "$msg"; or return 1
    command git push origin "$branch"
end

function merge_branch
    if test (count $argv) -lt 2
        echo "Usage: merge_branch <src> <tgt>" 1>&2
        return 1
    end

    set -l src $argv[1]
    set -l tgt $argv[2]

    command git fetch origin; or return 1
    command git checkout "$tgt"; or return 1
    command git pull origin "$tgt"; or return 1
    command git merge --no-ff "$src" -m "Merge branch '$src' into $tgt"; or return 1
    command git push origin "$tgt"
end

function git_blob_push
    if test (count $argv) -lt 1
        echo "Usage: git_blob_push <path/to/file> [remote] [branch]" 1>&2
        return 1
    end

    set -l file $argv[1]
    set -l remote origin
    if test (count $argv) -ge 2
        set remote $argv[2]
    end

    set -l branch (command git rev-parse --abbrev-ref HEAD 2>/dev/null)
    if test (count $argv) -ge 3
        set branch $argv[3]
    end

    if test -z "$branch"
        echo "Could not determine current branch." 1>&2
        return 1
    end

    if not test -e "$file"
        echo "File not found: $file" 1>&2
        return 1
    end

    command git push "$remote" "$branch"; or return 1

    set -l remote_url (command git remote get-url "$remote"); or return 1
    set remote_url (string replace -r '\.git$' '' -- $remote_url)

    if string match -qr '^git@.+:.+/.+' -- $remote_url
        set -l hostpath (string replace -r '^git@' '' -- $remote_url)
        set -l host (string split -m 1 ':' $hostpath)[1]
        set -l path (string split -m 1 ':' $hostpath)[2]
        set remote_url "https://$host/$path"
    end

    set -l commit (command git rev-parse HEAD); or return 1

    set -l rel (command git ls-files --full-name "$file" 2>/dev/null)
    if test -z "$rel"
        set -l root (command git rev-parse --show-toplevel); or return 1
        set rel (string replace "$root/" '' -- $file)
    end

    set -l url "$remote_url/blob/$commit/$rel"

    echo "Blob URL:"
    echo "  $url"

    if __apogee_copy $url
        echo "(copied to clipboard)"
    else
        echo "(clipboard tool not found; not copied)" 1>&2
    end
end
