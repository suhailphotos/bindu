-- Startup notes:
-- 1) Define <leader> *before* lazy.nvim loads. lazy sets up plugin keymaps during
--    startup, so the leader must exist now or plugins bind the wrong key (and
--    you’ll see the “set mapleader BEFORE loading lazy” warning).
-- 2) Load plugins (lazy_init) before our own module to avoid a color flash.
--    When we required("suhail") first, Neovim drew once with default colors and
--    then applied the Lilac theme, causing a brief palette flicker. Loading
--    lazy first lets the theme initialize before the first paint.
--    (If remap.lua also sets mapleader, that line is now redundant.)

vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- optional but nice
vim.loader.enable()          -- nvim ≥ 0.9
vim.opt.termguicolors = true

-- load plugins first so the theme applies instantly
require("suhail.lazy_init")

-- then the rest of your config
require("suhail")
