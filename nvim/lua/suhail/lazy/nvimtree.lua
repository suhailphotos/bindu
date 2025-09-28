-- lua/suhail/lazy/nvimtree.lua
return {
  "nvim-tree/nvim-tree.lua",
  version = "*",
  cmd = { "NvimTreeToggle", "NvimTreeFindFileToggle", "NvimTreeFocus" },
  keys = {
    { "<C-n>", "<cmd>NvimTreeToggle<CR>",           desc = "Explorer: toggle" },
    { "<leader>e", "<cmd>NvimTreeFindFileToggle<CR>", desc = "Explorer: focus current file" },
  },
  dependencies = { "nvim-tree/nvim-web-devicons" },
  opts = {
    disable_netrw = true,
    hijack_netrw  = true,
    sync_root_with_cwd = true,
    respect_buf_cwd   = true,
    update_focused_file = { enable = true, update_cwd = true },
    view = {
      side = "left",
      width = 34,
      preserve_window_proportions = true,
      signcolumn = "yes",
    },
    renderer = {
      highlight_git = true,
      indent_markers = { enable = true },
      icons = { git_placement = "after" },
      root_folder_label = ":~:s?$HOME??",
    },
    filters = { dotfiles = false, git_ignored = false },
    git = { enable = true, ignore = false },
    actions = {
      open_file = { quit_on_open = false, resize_window = true },
    },
  },
  config = function(_, opts)
    require("nvim-tree").setup(opts)

    -- Close if it's the last window (nice UX when you :q)
    vim.api.nvim_create_autocmd("QuitPre", {
      callback = function()
        local wins = vim.api.nvim_list_wins()
        if #wins == 1 then
          local buf = vim.api.nvim_get_current_buf()
          local ft  = vim.bo[buf].filetype
          if ft == "NvimTree" then vim.cmd("quit") end
        end
      end,
    })
    -- ANSI 0 selection for nvim-tree
    local function apply_tree_selection_ansi0()
      -- only do ANSI when mira is in ansi_only mode
      if vim.g.mira_ansi_only == true then
        vim.api.nvim_set_hl(0, "NvimTreeCursorLine", { ctermbg = 0 })  -- ← ANSI 0
      else
        -- fallback for truecolor themes, if you ever toggle
        vim.api.nvim_set_hl(0, "NvimTreeCursorLine", { bg = "#000000" })
      end
    end

    -- ensure the row highlight is visible in the tree window
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "NvimTree",
      callback = function()
        vim.wo.cursorline = true
        apply_tree_selection_ansi0()
      end,
    })

    -- re-apply on colorscheme switches
    vim.api.nvim_create_autocmd("ColorScheme", {
      callback = apply_tree_selection_ansi0,
    })
  end,
}
