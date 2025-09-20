-- lua/suhail/providers.lua
-- Silence providers you don't use (keeps :checkhealth green).
vim.g.loaded_node_provider = 0   -- or install: npm i -g neovim
vim.g.loaded_ruby_provider = 0   -- or: gem install neovim
vim.g.loaded_perl_provider = 0   -- or: cpanm Neovim::Ext
