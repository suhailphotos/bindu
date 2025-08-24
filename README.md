# bindu

**bindu** = “the dot.” This is my single-branch dotfiles repo. The **`main`** branch maps directly to `~/.config/` on every machine.

## layout

The repo root mirrors `~/.config`:
nvim/
tmux/
ghostty/
starship/
eza/
iterm/
**_…plus any other XDG configs_**
Extra assets that **don’t** live in `~/.config` (like `.p10k.zsh`) go under helper folders at repo root:

## install (no ansible)
```bash
git clone https://github.com/suhailphotos/bindu.git ~/.bindu
git -C ~/.bindu checkout --detach             # allow main to be used by a worktree
git -C ~/.bindu worktree add ~/.config main   # ~/.config is now a clean worktree
```
update later:
```
git -C ~/.bindu fetch origin
git -C ~/.config pull --ff-only
```

with ansible

My playbook ensures ~/.config is a git worktree pulled from bindu:main, then sets up Ghostty/iTerm, Neovim, tmux, Starship, etc.

notes
	•	Using a worktree keeps ~/.config clean and versioned.
	•	If you previously hosted ~/.config from another repo, detach that worktree first:

```
git -C ~/.helix worktree remove -f ~/.config || true
```

license

MIT

