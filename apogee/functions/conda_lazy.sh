# Lazy conda init (bash/zsh via .sh)
# Goals:
#   - Fast login (no hook at startup)
#   - conda activate works anytime
#   - no conda init / no dotfile edits

__apogee_conda_bin() {
  # Prefer explicit install locations
  if [ -x "$HOME/anaconda3/bin/conda" ]; then
    printf '%s\n' "$HOME/anaconda3/bin/conda"
    return 0
  fi
  if [ -x "$HOME/miniconda3/bin/conda" ]; then
    printf '%s\n' "$HOME/miniconda3/bin/conda"
    return 0
  fi

  # Fall back to PATH only if it's a real executable path
  _p="$(command -v conda 2>/dev/null || true)"
  [ -n "$_p" ] && [ -x "$_p" ] && printf '%s\n' "$_p" && return 0

  return 1
}

__apogee_conda_init_once() {
  [ -n "${__APOGEE_CONDA_INITIALIZED:-}" ] && return 0

  conda_bin="$(__apogee_conda_bin)" || return 1

  # Choose hook type based on shell (bash vs zsh)
  if [ -n "${ZSH_VERSION:-}" ]; then
    hook_shell="zsh"
  else
    hook_shell="bash"
  fi

  # Load conda’s shell functions into *this* shell
  eval "$("$conda_bin" "shell.${hook_shell}" "hook" 2>/dev/null)" || return 1

  __APOGEE_CONDA_INITIALIZED=1
  return 0
}

conda() {
  __apogee_conda_init_once || {
    printf '%s\n' "conda: failed to initialize conda" >&2
    return 1
  }

  # After init, conda defines/overwrites the `conda` function.
  # Calling `conda` here should invoke the new function (activate works).
  conda "$@"
}

mamba() {
  __apogee_conda_init_once || {
    printf '%s\n' "mamba: failed to initialize conda" >&2
    return 1
  }

  # mamba doesn't need conda's function for normal subcommands; keep it simple.
  command mamba "$@"
}
