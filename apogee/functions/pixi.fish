function pxg
  set -l ed nvim
  if set -q EDITOR
    set ed $EDITOR
  end
  $ed $PIXIH_HOST_TRACKED
end

function pxg_sync; pixi global sync; end
function pxg_list; pixi global list; end
function pxg_host; echo $PIXIH_HOST_TRACKED; end
function pxg_live; echo $PIXIH_LIVE_LINK; end
