-- --------------------------------------------------
-- Core
-- --------------------------------------------------
vim.g.mapleader = " "
if vim.loader and vim.loader.enable then vim.loader.enable() end
-- vim.opt.timeoutlen  = 300  -- default 1000; faster mapped-key sequences
-- vim.opt.ttimeoutlen = 10   -- faster keycode timeout


-- --------------------------------------------------
-- Providers such as npm (js), gen (ruby)
-- --------------------------------------------------
require("suhail.providers")


-- --------------------------------------------------
-- Bootstrap: lazy.nvim
-- --------------------------------------------------
require("suhail.lazy_init")

-- --------------------------------------------------
-- Python host resolver (fast, no imports at startup)
--  --------------------------------------------------
require("suhail.pythonhost").setup()

-- --------------------------------------------------
-- Keymaps (plugin-free)
-- --------------------------------------------------
require("suhail.remap")

-- --------------------------------------------------
-- Neovim Options
-- --------------------------------------------------
require("suhail.set")

-- --------------------------------------------------
-- Performance optimization
-- --------------------------------------------------
require("suhail.bigfile").setup()

-- --------------------------------------------------
-- Theme (default = Mira / ANSI)
-- --------------------------------------------------
pcall(require, "suhail.keys.theme")
-- Practice commands (lazy loads hardtime/vim-be-good on demand)
require("suhail.practice")
