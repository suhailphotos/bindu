-- --------------------------------------------------
-- Telescope (NvChad-style UI)
-- --------------------------------------------------
return {
  "nvim-telescope/telescope.nvim",
  version = false,
  cmd = "Telescope",
  dependencies = { "nvim-lua/plenary.nvim" },
  keys = {
    {
      "<leader>pf",
      function()
        require("telescope.builtin").find_files({
          sorting_strategy = "ascending",
          layout_strategy  = "horizontal",
          layout_config    = {
            prompt_position = "top",
            width = 0.95, height = 0.90,
            preview_width = 0.55, preview_cutoff = 80,
          },
          border = false,
          results_title = false,              -- keep results title hidden
          prompt_title  = "Find Files",       -- <- pill text
          preview_title = "File Preview",     -- <- pill text
          path_display = { "filename_first" },
          follow = true,
          hidden = true,
        })
      end,
      desc = "Files",
    },
    {
      "<C-p>",
      function()
        local builtin = require("telescope.builtin")
        local ok = pcall(builtin.git_files, {
          show_untracked = true,
          sorting_strategy = "ascending",
          layout_strategy  = "horizontal",
          layout_config    = {
            prompt_position = "top",
            width = 0.95,
            height = 0.90,
            preview_width = 0.55,
            preview_cutoff = 80,
          },
          border = false,
          results_title = false,
          preview_title = false,
          prompt_title = false,
          path_display = { "filename_first" },
        })
        if not ok then
          builtin.find_files({
            sorting_strategy = "ascending",
            layout_strategy  = "horizontal",
            layout_config    = {
              prompt_position = "top",
              width = 0.95,
              height = 0.90,
              preview_width = 0.55,
              preview_cutoff = 80,
            },
            border = false,
            results_title = false,
            preview_title = false,
            prompt_title = false,
            path_display = { "filename_first" },
            follow = true,
            hidden = true,
          })
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
        require("telescope.builtin").live_grep({
          sorting_strategy = "ascending",
          layout_strategy  = "horizontal",
          layout_config    = {
            prompt_position = "top",
            width = 0.95,
            height = 0.90,
            preview_width = 0.55,
            preview_cutoff = 80,
          },
          border = false,
          results_title = false,
          preview_title = false,
          prompt_title = false,
          path_display = { "filename_first" },
        })
      end,
      desc = "Grep (live)",
    },
  },
  config = function()
    local t = require("telescope")
    t.setup({
      defaults = {
        sorting_strategy = "ascending",
        layout_strategy  = "horizontal",
        layout_config    = {
          prompt_position = "top",
          width = 0.95,
          height = 0.90,
          preview_width = 0.55,
          preview_cutoff = 80,
        },
        border = false,
        winblend = 0,
        results_title = false,
        preview_title = false,
        prompt_title = false,
        path_display = { "filename_first" },
        dynamic_preview_title = true,
        selection_caret = " ",
        entry_prefix = "  ",
        prompt_prefix = "   ",
      },
    })

    -- Correct, safe call (fixes the earlier syntax/runtime issue)
    local ok, nv = pcall(require, "suhail.ui.telescope_nvchad")
    if ok and type(nv.apply) == "function" then nv.apply() end
  end,
}
