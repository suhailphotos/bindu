-- --------------------------------------------------
-- Telescope
-- --------------------------------------------------
return {
  "nvim-telescope/telescope.nvim",
  version = false,
  cmd = "Telescope",
  dependencies = { "nvim-lua/plenary.nvim" },
  keys = {
    { "<leader>pf", function() require("telescope.builtin").find_files() end, desc = "Files" },
    { "<C-p>",      function() require("telescope.builtin").git_files()  end, desc = "Git Files" },
    { "<leader>ps", function()
        require("telescope.builtin").grep_string({ search = vim.fn.input("Grep > ") })
      end, desc = "Grep (prompt)" },
  },
  config = function()
    require("telescope").setup({})
  end,
}
