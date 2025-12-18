function pxg {
  $ed = if ($env:EDITOR) { $env:EDITOR } else { "nvim" }
  & $ed $env:PIXIH_HOST_TRACKED
}

function pxg_sync { pixi global sync }
function pxg_list { pixi global list }
function pxg_host { $env:PIXIH_HOST_TRACKED }
function pxg_live { $env:PIXIH_LIVE_LINK }
