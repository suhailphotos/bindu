-- blank-start Neovim: no keymaps, no options, no colors
vim.g.mapleader = " "
vim.opt.termguicolors = true

-- bootstrap Lazy and load our single, minimal plugin spec
require("suhail.lazy_init")

-- do NOT set any colorscheme here
-- do NOT require anything else
