# uv + Orbit Docs

A tiny index for how you use **uv** with **Orbit**.

- `AddEnv.md` — create a new Python package under Matrix and wire it into Orbit (project envs).
- `UVToolManage.md` — manage **global** uv tools (separate shim dir, install/upgrade/uninstall, cleanup).

## Quick Links

- [AddEnv.md](./AddEnv.md)
- [UVToolManage.md](./UVToolManage.md)

## TL;DR

- **Project envs** live outside repos: `~/.venvs/<project>` (Orbit sets `UV_PROJECT_ENVIRONMENT` on the fly).
- **Global tools** are installed with `uv tool install <name>` and exposed via a shim (symlink) in `UV_TOOL_BIN_DIR` (e.g. `~/.local/share/uv/bin`).
- Keep the shim dir **outside** `~/.local/share/uv/tools` to avoid uv mistaking it for a tool.
