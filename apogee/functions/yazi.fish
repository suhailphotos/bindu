function y
  set -l tmp (mktemp -t 'yazi-cwd.XXXXXX'); or return
  yazi --cwd-file="$tmp" $argv
  if test -r "$tmp"
    set -l newcwd (cat -- "$tmp")
    if test -n "$newcwd"; and test "$newcwd" != (pwd)
      cd -- "$newcwd"
    end
    rm -f -- "$tmp"
  end
end

alias yy 'yazi'
alias yya 'yazi --chooser=append'
