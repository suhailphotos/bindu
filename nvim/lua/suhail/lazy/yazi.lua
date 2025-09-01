-- lua/suhail/lazy/yazi.lua
return {
  "mikavilpas/yazi.nvim",
  version = "*",
  event = "VeryLazy",
  dependencies = { "nvim-lua/plenary.nvim" },

  -- Gracefully disable on old Neovim
  enabled = function()
    if vim.fn.has("nvim-0.11") == 0 then
      vim.schedule(function()
        vim.notify("yazi.nvim requires Neovim 0.11+. Plugin disabled.", vim.log.levels.WARN)
      end)
      return false
    end
    return true
  end,

  -- Launch keys (Yazi is opt-in; netrw remains default elsewhere)
  keys = {
    { "<leader>pv", "<cmd>Yazi<cr>",        desc = "Yazi: project view" },
    { "<leader>yc", "<cmd>Yazi cwd<cr>",    desc = "Yazi: open in cwd" },
    { "<leader>yr", "<cmd>Yazi toggle<cr>", desc = "Yazi: resume/toggle" },
  },

  ---@type YaziConfig
  opts = {
    -- Keep netrw as the default for directories opened outside Yazi
    open_for_directories = false,

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
      -- For “copy relative path”
      resolve_relative_path_application =
        (vim.loop.os_uname().sysname == "Darwin") and "grealpath" or "realpath",
    },

    -- Behavior inside Yazi:
    -- - ENTER on a directory: reopen Yazi rooted in that directory (same as `l`)
    -- - ENTER on a file: open it in Neovim
    open_file_function = function(chosen_file, _config, _state)
      if type(chosen_file) == "string" and vim.fn.isdirectory(chosen_file) == 1 then
        -- Reopen Yazi in that directory without changing Neovim's CWD
        require("yazi").yazi({ cwd = chosen_file })
        return
      end
      vim.cmd("edit " .. vim.fn.fnameescape(chosen_file))
    end,
  },

  -- IMPORTANT: do NOT disable netrw here.
  -- (Remove any previous init() that set loaded_netrw/loaded_netrwPlugin.)
}
