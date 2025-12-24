function push_terminfo
    set -l host $argv[1]
    set -l term $argv[2]

    if test -z "$host"
        echo "Usage: push_terminfo user@host [TERM]" >&2
        return 1
    end

    if test -z "$term"
        if set -q TERM
            set term $TERM
        else
            set term xterm-256color
        end
    end

    if not type -q infocmp
        echo "push_terminfo: infocmp not found" >&2
        return 1
    end
    if not type -q tic
        echo "push_terminfo: tic not found (install ncurses/terminfo tools on the remote)" >&2
        return 1
    end
    if not type -q ssh
        echo "push_terminfo: ssh not found" >&2
        return 1
    end

    if not infocmp -x $term >/dev/null 2>&1
        echo "Local system doesn’t know term '$term'." >&2
        return 1
    end

    infocmp -x $term | ssh $host 'mkdir -p ~/.terminfo && tic -x -o ~/.terminfo /dev/stdin'
end

function terminfo_ok
    set -l host $argv[1]
    set -l term $argv[2]

    if test -z "$host"
        echo "Usage: terminfo_ok user@host [TERM]" >&2
        return 1
    end

    if test -z "$term"
        if set -q TERM
            set term $TERM
        else
            set term xterm-256color
        end
    end

    ssh $host "infocmp -x $term >/dev/null 2>&1 && echo '$term: OK' || echo '$term: MISSING'"
end
