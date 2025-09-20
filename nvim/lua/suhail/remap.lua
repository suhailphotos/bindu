-- --------------------------------------------------
-- Basics
-- --------------------------------------------------

-- move selected lines
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- join/scroll/search keeping cursor centered
vim.keymap.set("n", "J", "mzJ`z")
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- clipboard/yank/delete helpers
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]])
vim.keymap.set("n", "<leader>Y", [["+Y]])
vim.keymap.set({ "n", "v" }, "<leader>d", [["_d]])
vim.keymap.set("x", "<leader>p", [["_dP]])
vim.keymap.set("n", "Y", "yy")

-- splits
vim.keymap.set("n", "<leader>-", ":split<CR>")
vim.keymap.set("n", "<leader>\\", ":vsplit<CR>")
vim.keymap.set("n", "<leader>=", "<C-w>=")

-- quick actions
vim.keymap.set("n", "<leader><leader>", function() vim.cmd("so") end)
vim.keymap.set("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true })

-- optional “zoom” current split
vim.keymap.set("n", "<leader>z", function()
  if vim.t._zoomed then
    vim.t._zoomed = false; vim.cmd("wincmd =")
  else
    vim.t._zoomed = true; vim.cmd("wincmd |"); vim.cmd("wincmd _")
  end
end)
