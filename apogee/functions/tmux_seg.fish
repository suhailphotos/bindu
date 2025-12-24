function __apogee_tmux_seg_update
    set -l sym ''
    if set -q TMUX
        if test "$PWD" = "$HOME"
            set -gx STARSHIP_TMUX_SEG "$sym"
        else
            set -gx STARSHIP_TMUX_SEG " $sym "
        end
    else
        set -e STARSHIP_TMUX_SEG
    end
end

# update on directory change (cheap) + run once
function __apogee_tmux_seg_update_on_pwd --on-variable PWD
    __apogee_tmux_seg_update
end
__apogee_tmux_seg_update
