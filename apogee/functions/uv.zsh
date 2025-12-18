# uv zsh extras: keep UV_PROJECT_ENVIRONMENT synced on cd/prompt
autoload -Uz add-zsh-hook
add-zsh-hook chpwd  _apogee_uv_set_envvar
add-zsh-hook precmd _apogee_uv_set_envvar
