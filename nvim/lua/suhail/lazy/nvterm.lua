-- lua/suhail/lazy/nvterm.lua
return {
  "NvChad/nvterm",
  event = "VeryLazy",
  config = function()
    require("nvterm").setup({
      terminals = {
        shell = vim.o.shell,  -- respects $SHELL; matches your environment
        type_opts = {
          float = {
            relative = "editor",
            row = 0.08, col = 0.08,
            width = 0.84, height = 0.84,
            border = "rounded",
          },
          horizontal = { location = "rightbelow", split_ratio = 0.28 },
          vertical   = { location = "rightbelow", split_ratio = 0.36 },
        },
      },
      behavior = {
        autoclose_on_exit = true,
        close_on_exit = true,
      },
    })

    local nt = require("nvterm.terminal")
    local map = vim.keymap.set
    local opts = { silent = true, desc = "NvTerm" }

    -- Same feel as NvChad
    map({ "n", "t" }, "<A-i>", function() nt.toggle("float")       end, vim.tbl_extend("force", opts, { desc = "Terminal (float)" }))
    map({ "n", "t" }, "<A-h>", function() nt.toggle("horizontal")  end, vim.tbl_extend("force", opts, { desc = "Terminal (horizontal)" }))
    map({ "n", "t" }, "<A-v>", function() nt.toggle("vertical")    end, vim.tbl_extend("force", opts, { desc = "Terminal (vertical)" }))

    -- Quick escape from terminal to Normal
    vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], { silent = true, desc = "Terminal: normal mode" })
  end,
}
