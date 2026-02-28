-- --------------------------------------------------
-- lua/suhail/lazy/treesitter.lua
-- --------------------------------------------------
return {
  "nvim-treesitter/nvim-treesitter",
  lazy = false,            -- recommended by the plugin (no lazy-loading)
  build = ":TSUpdate",

  config = function()
    local ok, ts = pcall(require, "nvim-treesitter")
    if not ok then
      vim.notify("nvim-treesitter not found", vim.log.levels.ERROR)
      return
    end

    -- Optional: tell it where to install parsers/queries (your checkhealth shows this path)
    ts.setup({
      install_dir = vim.fn.stdpath("data") .. "/site",
    })

    -- Install parsers you care about (async, no-op if already installed)
    ts.install({
      "vimdoc", "vim", "lua", "bash",
      "javascript", "typescript", "json", "yaml", "toml",
      "python", "rust", "c",
      "markdown", "markdown_inline",
      "dockerfile", "gitignore", "tmux",
    }, { summary = false })

    -- IMPORTANT: enable highlighting by starting Tree-sitter per buffer
    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("SuhailTreesitterStart", { clear = true }),
      pattern = {
        "python", "lua", "rust", "c", "bash",
        "javascript", "typescript", "json", "yaml", "toml",
        "markdown", "markdown_inline",
        "dockerfile", "gitignore", "tmux",
        "vim", "vimdoc",
      },
      callback = function(ev)
        -- Start TS highlighting for this buffer
        pcall(vim.treesitter.start, ev.buf)

        -- Optional extras (uncomment if you want them):
        -- vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        -- vim.wo[ev.buf].foldexpr  = "v:lua.vim.treesitter.foldexpr()"
        -- vim.wo[ev.buf].foldmethod = "expr"
      end,
    })
  end,
}
