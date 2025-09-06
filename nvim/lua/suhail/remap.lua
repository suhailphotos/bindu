vim.g.mapleader = " "
-- Replace netrw “project view” with Yazi
vim.keymap.set('n', "<leader>pv", "<cmd>Yazi<CR>", { desc = "Yazi: project view" })

-- move selected lines up/down
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

vim.keymap.set("n", "J", "mzJ`z")
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- clipboard/yank helpers
vim.keymap.set({"n","v"}, "<leader>y", [["+y]])
vim.keymap.set("n", "<leader>Y", [["+Y]])
vim.keymap.set({"n","v"}, "<leader>d", [["_d]])
vim.keymap.set("n", "Y", "yy")

vim.keymap.set("x", "<leader>p", [["_dP]])  -- paste without clobbering
vim.keymap.set("i", "<C-c>", "<Esc>")       -- controversial but handy

vim.keymap.set("n", "Q", "<nop>")
vim.keymap.set("n", "<leader>f", function() vim.lsp.buf.format({ async = true }) end)

vim.keymap.set("n", "<C-k>", "<cmd>cnext<CR>zz")
vim.keymap.set("n", "<C-j>", "<cmd>cprev<CR>zz")
vim.keymap.set("n", "<leader>k", "<cmd>lnext<CR>zz")
vim.keymap.set("n", "<leader>j", "<cmd>lprev<CR>zz")

vim.keymap.set("n", "<leader>s",
  [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])
vim.keymap.set("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true })

-- safe source current file
vim.keymap.set("n", "<leader><leader>", function() vim.cmd("so") end)

-- Optional: tmux sessionizer (won't error if missing)
vim.keymap.set("n", "<C-f>", function()
  vim.fn.jobstart({"tmux", "neww", "tmux-sessionizer"}, { detach = true })
end, { silent = true })

-- ----------------------------------------
-- Unified splits (match Ghostty & tmux)
-- ----------------------------------------
-- minus = down (horizontal split)
vim.keymap.set("n", "<leader>-",  ":split<CR>",  { desc = "Split below (horizontal)" })
-- backslash = right (vertical split)
vim.keymap.set("n", "<leader>\\", ":vsplit<CR>", { desc = "Split right (vertical)" })

-- helpers
vim.keymap.set("n", "<leader>=", "<C-w>=", { desc = "Equalize splits" })

-- optional zoom toggle similar to tmux zoom
vim.keymap.set("n", "<leader>z", function()
  if vim.t._zoomed then
    vim.t._zoomed = false
    vim.cmd("wincmd =")
  else
    vim.t._zoomed = true
    vim.cmd("wincmd |")
    vim.cmd("wincmd _")
  end
end, { desc = "Toggle zoom current split" })


-- On-demand netrw (coexists cleanly with Yazi)
vim.api.nvim_create_user_command("Netrw", function(opts)
  -- If netrw isn't active (e.g. you disabled it somewhere), load it now
  if vim.fn.exists(":Lexplore") ~= 2 then
    vim.g.loaded_netrw = nil
    vim.g.loaded_netrwPlugin = nil
    vim.cmd("runtime! plugin/netrwPlugin.vim")
  end

  -- open provided path or the current file's directory
  local target = (opts.args ~= "" and opts.args) or vim.fn.expand("%:p:h")
  vim.cmd("Lexplore " .. vim.fn.fnameescape(target))
end, {
  nargs = "?",           -- :Netrw or :Netrw ~/Downloads
  complete = "dir",
  desc = "Open netrw (left explorer) without affecting Yazi",
})
