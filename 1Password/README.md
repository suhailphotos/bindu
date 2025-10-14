# 1Password SSH Agent — dotfiles README

This folder is version‑controlled in **bindu** (`~/.config`). It contains the **declarative config** for the 1Password SSH Agent so new machines can be brought online consistently.

- Repo path (tracked): `~/.config/1Password/ssh/agent.toml`
- Runtime path (macOS): `~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.toml`
- Agent socket path (macOS, behind the scenes): `~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock`
- **Symlink we standardize on:** `~/.1password/agent.sock` → the long Group Containers socket

> `agent.toml` is **not** a private key. Your private SSH keys remain inside 1Password. This file only controls agent behavior (allowed accounts, prompts, etc.).

---

## How this repo integrates with your machines

Your Helix script (`ssh_config_local.sh`) wires everything up:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/suhailphotos/helix/refs/heads/main/scripts/ssh_config_local.sh)"   -- --include-macos --github-1password --install-1p-agent-config --github-add-key
```

What those flags do:

- `--github-1password`  
  Creates **`~/.1password/agent.sock`** (symlink) and writes `~/.ssh/config.d/10-github.conf` to point only GitHub at the 1P agent.
- `--install-1p-agent-config`  
  Copies the repo’s `~/.config/1Password/ssh/agent.toml` into 1Password’s sandbox path on macOS (idempotent; won’t overwrite unless forced).
- `--github-add-key`  
  Reads your GitHub public key from 1Password (`op://security/GitHub/public key`) and adds it to your GitHub account with `gh` if it isn’t there already.

You can safely re‑run the script any time. It backs up `~/.ssh/config`, rewrites snippets, and keeps things consistent.

---

## What gets written to `~/.ssh`

- Base: `~/.ssh/config`  
  Includes a commented `IdentityAgent ~/.1password/agent.sock` for global opt‑in.
- Snippets: `~/.ssh/config.d/*.conf` from your Ansible inventory.
- GitHub only: `~/.ssh/config.d/10-github.conf`
  ```sshconfig
  Host github.com
    HostName github.com
    User git
    IdentityAgent ~/.1password/agent.sock
    IdentitiesOnly yes        # (recommended to avoid probing on‑disk keys)
  ```

If you pass `--use-1password`, the base config will **uncomment** the global `IdentityAgent` line so **all** SSH hosts use 1Password by default.

---

## First‑run checklist (macOS)

1. **Enable the 1Password SSH Agent:**
   - 1Password → Settings → **Developer** → “Use the SSH agent” (wording may vary).

2. **Ensure the symlink exists (script will do this):**
   ```bash
   ls -l ~/.1password/agent.sock
   # should point to .../Library/Group Containers/.../agent.sock
   ```

3. **Install `agent.toml` into the sandbox (script will do this):**
   - Source: `~/.config/1Password/ssh/agent.toml`
   - Dest:   `~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.toml`

4. **Fully restart 1Password after installing `agent.toml`:**
   - Quit 1Password **completely** (including Quick Access/menubar), then reopen.
   - This forces the agent to reload its config.

5. **Test GitHub over SSH:**
   ```bash
   ssh -G github.com | grep -i identityagent
   # → IdentityAgent /Users/<you>/.1password/agent.sock

   ssh -Tv git@github.com
   # → “You've successfully authenticated, but GitHub does not provide shell access.”
   ```

> If `ssh-add -l` says “agent contains no identities”, restart 1Password. You can also explicitly bind the sock for that one command:
> ```bash
> SSH_AUTH_SOCK="$HOME/.1password/agent.sock" ssh-add -l || true
> ```

---

## Linux note

On Linux, 1Password already exposes the agent at `~/.1password/agent.sock`. The same SSH snippets work as‑is. The macOS‑specific symlink step is harmless on Linux.

---

## Troubleshooting quick hits

- **Permission denied (publickey)** on GitHub  
  - Verify the agent is being used: `ssh -G github.com | rg identityagent`
  - Ensure your GitHub public key exists in 1Password and on GitHub. The script’s `--github-add-key` helps:
    ```bash
    gh api user/keys --jq '.[].key' | rg "$(op read 'op://security/GitHub/public key' | tr -d '
')"
    ```
- **No identities in agent**  
  - Restart 1Password after updating `agent.toml`.
  - Confirm the 1Password item that holds your SSH key is set to **Allow** with the agent (per 1P UI).

- **SSH still tries on‑disk keys**  
  - Add `IdentitiesOnly yes` to any host you want to force through the agent.

---

## FAQ

**Do I need to export `SSH_AUTH_SOCK` in my shell?**  
No. Your SSH config uses `IdentityAgent ~/.1password/agent.sock`, which overrides the socket per host. `SSH_AUTH_SOCK` is only handy for ad‑hoc commands like `ssh-add -l`.

**Does this overwrite `agent.toml` every run?**  
No. The helper copies when missing or identical. You can force an overwrite via the script’s `--force-1p-agent-config` flag (if enabled).

**Is `agent.toml` sensitive?**  
It contains agent policy and prompts, not private keys. Keep it private anyway since it reflects how your agent is configured.

---

## Maintenance

- Update `~/.config/1Password/ssh/agent.toml` in the repo → commit → pull on other machines → run the Helix script → restart 1Password.
- To switch everything to 1Password globally, re‑run the script with `--use-1password` (or manually uncomment `IdentityAgent` in `~/.ssh/config`).

---

## Smoke‑test commands (copy/paste)

```bash
# Show where SSH will look for the agent on GitHub
ssh -G github.com | rg -i identityagent

# Verbose handshake with GitHub
ssh -Tv git@github.com

# See identities via the 1P agent for this command
SSH_AUTH_SOCK="$HOME/.1password/agent.sock" ssh-add -l || true
```
