function __apogee_conda_bin
    if test -x "$HOME/anaconda3/bin/conda"
        echo "$HOME/anaconda3/bin/conda"
        return 0
    end
    if test -x "$HOME/miniconda3/bin/conda"
        echo "$HOME/miniconda3/bin/conda"
        return 0
    end
    if type -q conda
        set -l p (command -v conda)
        if test -x "$p"
            echo "$p"
            return 0
        end
    end
    return 1
end

function __apogee_conda_init_once
    if set -q __APOGEE_CONDA_INITIALIZED
        return 0
    end

    set -l conda_bin (__apogee_conda_bin); or return 1

    # fish hook prints fish code (defines conda function)
    eval ($conda_bin shell.fish hook 2>/dev/null); or return 1

    set -g __APOGEE_CONDA_INITIALIZED 1
    return 0
end

function conda
    __apogee_conda_init_once; or begin
        echo "conda: failed to initialize conda" >&2
        return 1
    end

    # After init, the hook defines/replaces `conda`, so this calls the real one.
    conda $argv
end

function mamba
    __apogee_conda_init_once; or begin
        echo "mamba: failed to initialize conda" >&2
        return 1
    end
    command mamba $argv
end
