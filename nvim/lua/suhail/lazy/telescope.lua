-- --------------------------------------------------
-- Telescope
-- --------------------------------------------------
return {
  "nvim-telescope/telescope.nvim",
  version = false,
  cmd = "Telescope",
  dependencies = { "nvim-lua/plenary.nvim" },
  keys = {
    {
      "<leader>pf",
      function() require("telescope.builtin").find_files() end,
      desc = "Files",
    },
    {
      "<C-p>",
      function()
        local builtin = require("telescope.builtin")
        local ok = pcall(builtin.git_files, { show_untracked = true })
        if not ok then
          builtin.find_files()
        end
      end,
      desc = "Git Files (fallback to Files)",
    },
    {
      "<leader>ps",
      function()
        if vim.fn.executable("rg") == 0 then
          vim.notify("ripgrep (rg) not found; grep disabled.", vim.log.levels.WARN)
          return
        end
        require("telescope.builtin").grep_string({ search = vim.fn.input("Grep > ") })
      end,
      desc = "Grep (prompt)",
    },
  },
  config = function()
    require("telescope").setup({})
  end,
}
