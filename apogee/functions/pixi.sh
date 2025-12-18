# pixi helpers (sh family)

pxg() {
  "${EDITOR:-nvim}" "${PIXIH_HOST_TRACKED:?PIXIH_HOST_TRACKED not set}"
}

pxg_sync() { pixi global sync; }
pxg_list() { pixi global list; }
pxg_host() { printf '%s\n' "${PIXIH_HOST_TRACKED:-}"; }
pxg_live() { printf '%s\n' "${PIXIH_LIVE_LINK:-}"; }
