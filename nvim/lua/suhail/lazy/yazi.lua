-- --------------------------------------------------
-- Yazi file navigator
-- --------------------------------------------------
return {
  "mikavilpas/yazi.nvim",
  version = "*",
  event = "VeryLazy",
  dependencies = { "nvim-lua/plenary.nvim" },
  keys = {
    { "<leader>pv", "<cmd>Yazi<cr>",        desc = "Project view (Yazi)" },
    { "<leader>yc", "<cmd>Yazi cwd<cr>",    desc = "Yazi: open CWD" },
    { "<leader>yr", "<cmd>Yazi toggle<cr>", desc = "Yazi: resume/toggle" },
  },
  opts = {
    open_for_directories = false,
    keymaps = { change_working_directory = false, show_help = "<f1>" },
    floating_window_border = "rounded",
    floating_window_scaling_factor = 0.95,
    yazi_floating_window_winblend = 0,
    highlight_hovered_buffers_in_same_directory = true,
    integrations = {
      resolve_relative_path_application =
        (vim.loop.os_uname().sysname == "Darwin") and "grealpath" or "realpath",
    },
    open_file_function = function(chosen_file)
      if type(chosen_file) == "string" and vim.fn.isdirectory(chosen_file) == 1 then
        require("yazi").yazi({ cwd = chosen_file })
        return
      end
      vim.cmd.edit(vim.fn.fnameescape(chosen_file))
    end,
  },
}
