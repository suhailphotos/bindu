-- ====================================================================
-- Leader & Project View
-- ====================================================================
vim.g.mapleader = " "
-- Replace netrw “project view” with Yazi
vim.keymap.set('n', "<leader>pv", "<cmd>Yazi<CR>", { desc = "Yazi: project view" })


-- ====================================================================
-- Move Lines & Scrolling Helpers
-- ====================================================================
-- move selected lines up/down
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- keep cursor centered on join/half-page moves & search next/prev
vim.keymap.set("n", "J", "mzJ`z")
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")


-- ====================================================================
-- Clipboard / Yank / Delete
-- ====================================================================
vim.keymap.set({"n","v"}, "<leader>y", [["+y]])
vim.keymap.set("n", "<leader>Y", [["+Y]])
vim.keymap.set({"n","v"}, "<leader>d", [["_d]])
vim.keymap.set("n", "Y", "yy")

-- paste without clobbering register
vim.keymap.set("x", "<leader>p", [["_dP]])

-- quick escape in insert (controversial but handy)
vim.keymap.set("i", "<C-c>", "<Esc>")


-- ====================================================================
-- Page Navigation (centered)
-- ====================================================================
vim.keymap.set("n", "<C-M-d>", "<C-f>zz", { desc = "Page down (center)", silent = true })
vim.keymap.set("n", "<C-M-u>", "<C-b>zz", { desc = "Page up (center)",   silent = true })


-- ====================================================================
-- Formatting / Misc
-- ====================================================================
vim.keymap.set("n", "Q", "<nop>")
vim.keymap.set("n", "<leader>f", function() vim.lsp.buf.format({ async = true }) end)


-- ====================================================================
-- Quickfix & Location List Navigation
-- ====================================================================
vim.keymap.set("n", "<C-k>", "<cmd>cnext<CR>zz")
vim.keymap.set("n", "<C-j>", "<cmd>cprev<CR>zz")
vim.keymap.set("n", "<leader>k", "<cmd>lnext<CR>zz")
vim.keymap.set("n", "<leader>j", "<cmd>lprev<CR>zz")


-- ====================================================================
-- Search & File Permissions
-- ====================================================================
-- substitute word under cursor (global, case-insensitive, positioned)
vim.keymap.set("n", "<leader>s",
  [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])

-- make current file executable
vim.keymap.set("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true })


-- ====================================================================
-- Source Current File
-- ====================================================================
vim.keymap.set("n", "<leader><leader>", function() vim.cmd("so") end)


-- ====================================================================
-- Optional: tmux Sessionizer
-- ====================================================================
vim.keymap.set("n", "<C-f>", function()
  vim.fn.jobstart({"tmux", "neww", "tmux-sessionizer"}, { detach = true })
end, { silent = true })


-- ====================================================================
-- Unified Splits (match Ghostty & tmux)
-- ====================================================================
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


-- ====================================================================
-- Close & Pick New (Telescope / Yazi)
-- ====================================================================
-- close current buffer and open Telescope find_files
vim.keymap.set("n", "<leader>nf", function()
  vim.cmd("bd")
  require("telescope.builtin").find_files()
end, { desc = "New file (close current + Telescope)" })

-- close current buffer and open Yazi
vim.keymap.set("n", "<leader>nv", function()
  vim.cmd("bd")
  vim.cmd("Yazi") -- adjust if your Yazi command is different
end, { desc = "New file (close current + Yazi)" })


-- ====================================================================
-- On-demand netrw (coexists cleanly with Yazi)
-- ====================================================================
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
