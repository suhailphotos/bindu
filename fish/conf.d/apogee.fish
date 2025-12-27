if test -d $HOME/.cargo/bin
  fish_add_path -g -p $HOME/.cargo/bin
end

if type -q apogee
  apogee | source
end

if type -q starship
  starship init fish | source
end
