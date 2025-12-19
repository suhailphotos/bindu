# pixi helpers (sh family)

# zsh: avoid "defining function based on alias" if pxg already exists as an alias
unalias pxg pxg_sync pxg_list pxg_host pxg_live 2>/dev/null || true

pxg() {
  "${EDITOR:-nvim}" "${PIXIH_HOST_TRACKED:?PIXIH_HOST_TRACKED not set}"
}

pxg_sync() { pixi global sync; }
pxg_list() { pixi global list; }
pxg_host() { printf '%s\n' "${PIXIH_HOST_TRACKED:-}"; }
pxg_live() { printf '%s\n' "${PIXIH_LIVE_LINK:-}"; }
