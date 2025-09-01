-- lua/suhail/lazy/yazi.lua
return {
  "mikavilpas/yazi.nvim",
  version = "*",
  event = "VeryLazy",
  dependencies = { "nvim-lua/plenary.nvim" },

  -- Gracefully disable on old Neovim
  enabled = function()
    local ok = vim.fn.has("nvim-0.11") == 1
    if not ok then
      vim.schedule(function()
        vim.notify("yazi.nvim requires Neovim 0.11+. Plugin disabled.", vim.log.levels.WARN)
      end)
    end
    return ok
  end,

  -- Launch keys (don’t use <leader>- or <leader>\ here so they stay reserved for splits)
  keys = {
    { "<leader>pv", "<cmd>Yazi<cr>",        desc = "Yazi: project view" },
    { "<leader>yc", "<cmd>Yazi cwd<cr>",    desc = "Yazi: open in cwd" },
    { "<leader>yr", "<cmd>Yazi toggle<cr>", desc = "Yazi: resume/toggle" },
  },

  ---@type YaziConfig
  opts = {
    open_for_directories = false,  -- flip to true later if you want :e . to open Yazi
    keymaps = {
      show_help = "<f1>",
      -- Avoid conflict with your tmux-nav <C-\> binding
      change_working_directory = false,
    },
    floating_window_border = "rounded",
    floating_window_scaling_factor = 0.95,
    yazi_floating_window_winblend = 0,

    highlight_hovered_buffers_in_same_directory = true,

    integrations = {
      -- For “copy relative path” action:
      resolve_relative_path_application =
        (vim.loop.os_uname().sysname == "Darwin") and "grealpath" or "realpath",
    },
  },

  -- If you later set open_for_directories=true, uncomment these to fully disable netrw.
  init = function()
    -- vim.g.loaded_netrw = 1
    -- vim.g.loaded_netrwPlugin = 1
  end,
}
