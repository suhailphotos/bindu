# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000
# >>>>> Setup Environment <<<<<
if [[ -z "$BASE_DIR" ]]; then
  if [[ -f "$HOME/Dropbox/matrix/shellscripts/envars/setup_env.sh" ]]; then
    source "$HOME/Dropbox/matrix/shellscripts/envars/setup_env.sh" || {
      echo "Warning: setup_env.sh encountered issues during execution." >&2
    }
  else
    echo "Warning: setup_env.sh not found at expected location: $HOME/Dropbox/matrix/shellscripts/envars/setup_env.sh" >&2
  fi
fi

# >>>>> Source Scripts <<<<<
if [[ -n "$BASE_DIR" ]]; then
  for script in generalScripts/aliases.sh \
                gitUtils/gitUtils.sh \
                apiScripts/tailscale_api.sh; do
    script_path="$BASE_DIR/$script"
    if [[ -f "$script_path" ]]; then
      source "$script_path" || echo "Warning: Could not source $script_path" >&2
    else
      echo "Warning: Script not found at $script_path" >&2
    fi
  done
else
  echo "Warning: BASE_DIR is not set. Cannot source scripts." >&2
fi
# <<<<< Source Scripts <<<<<
# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# Color definitions for Rose Pine
RP_BLACK="\[\033[38;2;40;42;54m\]"     # Rose Pine Black (base)
RP_RED="\[\033[38;2;191;97;106m\]"     # Rose Pine Red (highlight)
RP_TEAL="\[\033[38;2;156;207;216m\]"   # Rose Pine Teal (custom highlight)
RP_GREEN="\[\033[38;2;163;190;140m\]"  # Rose Pine Green (highlight)
RP_ORANGE="\[\033[38;2;252;252;199m\]" # Rose Pine Orange (custom highlight)
RP_GOLD="\[\033[38;2;246;193;119m\]"   # Rose Pine Gold (custom highlight)
RP_ROSE="\[\033[38;2;235;188;186m\]"   # Rose Pine Rose (custom highlight)
RP_YELLOW="\[\033[38;2;235;203;139m\]" # Rose Pine Yellow (highlight)
RP_BLUE="\[\033[38;2;148;195;227m\]"   # Rose Pine Blue (highlight)
RP_MAGENTA="\[\033[38;2;180;142;173m\]" # Rose Pine Magenta (highlight)
RP_PURPLE="\[\033[38;2;110;106;134m\]" # Rose Pine Purple (highlight)
RP_CYAN="\[\033[38;2;136;192;208m\]"   # Rose Pine Cyan (highlight)
RP_WHITE="\[\033[38;2;229;233;240m\]"  # Rose Pine White (foreground)
RP_RESET="\[\033[00m\]"                # Reset color

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi

############################################################
# Smart-path prompt: prefix PWD with env variable if it matches
#
#   • Add any directory-style env vars in SMART_PATH_VARS.
#   • Falls back to normal ~ substitution for $HOME.
############################################################

# 1) List of candidate env vars (order matters)
SMART_PATH_VARS=( ML4VFX BASE_DIR )

# 2) Helper that prints $PWD with substitution
short_pwd () {
  local dir="$PWD"
  # if PWD is under one of your SMART_PATH_VARS, show $VAR-relative path
  for var in "${SMART_PATH_VARS[@]}"; do
    local val="${!var}"
    if [[ -n $val && "$dir" == "$val"* ]]; then
      printf '%s\n' "\$$var${dir#$val}"
      return
    fi
  done

  # Home directory logic: if $PWD == $HOME, show ~
  if [[ "$dir" == "$HOME" ]]; then
    printf '~\n'
    return
  fi

  # If $PWD is under $HOME (e.g. /home/suhail/projects)
  if [[ "$dir" == "$HOME/"* ]]; then
    printf '~/%s\n' "${dir#"$HOME/"}"
    return
  fi

  # Otherwise, show the full path
  printf '%s\n' "$dir"
}

# 3) Build the prompt
if [ "$color_prompt" = yes ]; then
  PS1="${debian_chroot:+($debian_chroot)}${RP_TEAL}\u@\h${RP_RESET}:${RP_ROSE}\$(short_pwd)${RP_RESET}\$ "
else
  PS1="${debian_chroot:+($debian_chroot)}\u@\h:\$(short_pwd)\$ "
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# colored GCC warnings and errors
#export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

if [ -f ~/.dircolors ]; then
    eval "$(dircolors -b ~/.dircolors)"
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi
export PATH=/usr/local/cuda/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/home/suhail/anaconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/home/suhail/anaconda3/etc/profile.d/conda.sh" ]; then
        . "/home/suhail/anaconda3/etc/profile.d/conda.sh"
    else
        export PATH="/home/suhail/anaconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<
#
# >>>>> Setup Environment <<<<<
if [[ -z "$BASE_DIR" ]]; then
  if [[ -f "$HOME/Dropbox/matrix/shellscripts/envars/setup_env.sh" ]]; then
    source "$HOME/Dropbox/matrix/shellscripts/envars/setup_env.sh" || {
      echo "Warning: setup_env.sh encountered issues during execution." >&2
    }
  else
    echo "Warning: setup_env.sh not found at expected location: $HOME/Dropbox/matrix/shellscripts/envars/setup_env.sh" >&2
  fi
fi

# >>>>> Source Scripts <<<<<
if [[ -n "$BASE_DIR" ]]; then
  for script in generalScripts/aliases.sh \
                gitUtils/gitUtils.sh \
                apiScripts/tailscale_api.sh; do
    script_path="$BASE_DIR/$script"
    if [[ -f "$script_path" ]]; then
      source "$script_path" || echo "Warning: Could not source $script_path" >&2
    else
      echo "Warning: Script not found at $script_path" >&2
    fi
  done
else
  echo "Warning: BASE_DIR is not set. Cannot source scripts." >&2
fi
# <<<<< Source Scripts <<<<<
. "$HOME/.cargo/env"

# Created by `pipx` on 2025-05-10 22:56:54
export PATH="$PATH:/home/suhail/.local/bin"
