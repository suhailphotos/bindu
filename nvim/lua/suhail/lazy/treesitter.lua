-- --------------------------------------------------
-- lua/suhail/lazy/treesitter.lua
-- --------------------------------------------------
return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  lazy = false,

  config = function()
    ----------------------------------------------------------------------
    -- NEW API (rewrite): nvim-treesitter exposes setup()/install()
    ----------------------------------------------------------------------
    local ok_new, ts = pcall(require, "nvim-treesitter")
    if ok_new and type(ts.setup) == "function" then
      -- setup installer location (optional)
      pcall(ts.setup, {
        install_dir = vim.fn.stdpath("data") .. "/site",
      })

      -- install list only if the function exists
      if type(ts.install) == "function" then
        pcall(ts.install, {
          "vimdoc", "vim", "lua", "bash",
          "javascript", "typescript", "json", "yaml", "toml",
          "python", "rust", "c",
          "markdown", "markdown_inline",
          "dockerfile", "gitignore", "tmux",
        }, { summary = false })
      end

      -- start TS highlighting per-buffer (needed on new API)
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("SuhailTreesitterStart", { clear = true }),
        callback = function(ev)
          pcall(vim.treesitter.start, ev.buf)
        end,
      })

      return
    end

    ----------------------------------------------------------------------
    -- OLD API (classic): require("nvim-treesitter.configs").setup(opts)
    ----------------------------------------------------------------------
    local ok_old, configs = pcall(require, "nvim-treesitter.configs")
    if ok_old and type(configs.setup) == "function" then
      configs.setup({
        ensure_installed = {
          "vimdoc", "vim", "lua", "bash",
          "javascript", "typescript", "json", "yaml", "toml",
          "python", "rust", "c",
          "markdown", "markdown_inline",
          "dockerfile", "gitignore", "tmux",
        },
        sync_install = false,
        auto_install = false,
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = { "markdown" },
        },
        indent = { enable = true },
      })
      return
    end

    vim.notify("treesitter: no supported API found (new or old)", vim.log.levels.ERROR)
  end,
}
