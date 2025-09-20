# Python host (portable & uv-aware)

Neovim needs a **Python 3 host** with the `pynvim` package installed to power Python plugins and `:py3` commands.

This setup is **portable** across macOS + Linux and avoids per-machine paths.

---

## How it works

The logic lives in `lua/suhail/pythonhost.lua`. On startup it **chooses** the best interpreter and sets:

```lua
vim.g.python3_host_prog = "/path/to/python"
```

### Selection order

1. **`~/.venvs/nvim/bin/python`** — preferred (matches mac + uv tooling).
2. **Conda** — if a Conda env is active (`CONDA_PREFIX`), use its `bin/python`.
3. **System Python** — `/usr/bin/python3` or first `python3` on `PATH`.

> The module **does not import Python at startup**. Health checks and imports only run when you ask (snappy startup).

### Commands

- `:PythonHostStatus` — prints which interpreter will be used.
- `:PythonHostCheck` — tries `import pynvim` via the chosen interpreter and suggests the right install command for your OS/env.

If you ever remove `pythonhost.lua`, nothing else breaks; you can hard-set the host in `init.lua` instead. Keeping it modular is the goal.

---

## Fixing “pynvim NOT found”

Pick the case that matches the machine.

### macOS (uv default)

Ansible already creates `~/.venvs/nvim` and installs `pynvim`. If you need to repair:

```bash
uv python install 3.11.7         # or your pinned version
uv venv --python 3.11.7 ~/.venvs/nvim
uv pip install --python ~/.venvs/nvim/bin/python -U pynvim
```

Then in Neovim: `:PythonHostCheck`.

### Linux — system Python (Debian/Ubuntu PEP 668)

Don’t `pip install` into `/usr`. Use the distro package:

```bash
sudo apt update
sudo apt install python3-neovim   # sometimes named python3-pynvim
```

Verify:

```bash
python3 -c "import pynvim, sys; print('pynvim', pynvim.__version__, 'via', sys.executable)"
```

### Linux — Conda (e.g. **nimbus**)

Install into the env Neovim will use:

```bash
# Option A: conda
conda install -n base -c conda-forge pynvim  # or the specific env you use

# Option B: uv using Conda's python explicitly (no env activation required)
uv pip install -U --python "/home/suhail/anaconda3/bin/python" pynvim
```

Then: `:PythonHostStatus` and `:PythonHostCheck`.

### Linux — uv (match mac layout)

If you want everything uv-managed (recommended long-term):

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh     # if uv missing
uv python install 3.11.7
uv venv --python 3.11.7 ~/.venvs/nvim
uv pip install --python ~/.venvs/nvim/bin/python -U pynvim
```

The resolver will pick `~/.venvs/nvim/bin/python` automatically.

---

## FAQ / Notes

- **Performance**: no blocking Python import runs during startup; only on `:PythonHostCheck`.
- **No env activation**: we never `conda activate` or `source` anything—Neovim just points to an interpreter path.
- **Override, if ever needed**: you can hard-set early in `init.lua`:
  ```lua
  vim.g.python3_host_prog = vim.fn.expand("~/.venvs/nvim/bin/python")
  ```
  but the resolver makes this unnecessary (and safer across machines).

- **Ansible**: macOS role `python_toolchain` creates `~/.venvs/nvim` via uv and installs `pynvim`. When you later migrate Linux to uv, repeat the same 3-liner above.
