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

    local nt   = require("nvterm.terminal")
    local map  = vim.keymap.set
    local opts = { silent = true, desc = "NvTerm" }

    --------------------------------------------------------------------------
    -- Terminal toggles
    -- NOTE: horizontal uses explicit Shift so Notio treats it distinctly
    --------------------------------------------------------------------------
    map({ "n", "t" }, "<A-i>", function()
      nt.toggle("float")
      if vim.bo.buftype == "terminal" then vim.cmd("startinsert") end
    end, vim.tbl_extend("force", opts, { desc = "Terminal (float)" }))

    map({ "n", "t" }, "<A-S-h>", function()  -- Alt+Shift+h
      nt.toggle("horizontal")
      if vim.bo.buftype == "terminal" then vim.cmd("startinsert") end
    end, vim.tbl_extend("force", opts, { desc = "Terminal (horizontal)" }))

    map({ "n", "t" }, "<A-v>", function()
      nt.toggle("vertical")
      if vim.bo.buftype == "terminal" then vim.cmd("startinsert") end
    end, vim.tbl_extend("force", opts, { desc = "Terminal (vertical)" }))

    -- Quick escape from terminal-job mode → Normal
    map("t", "<Esc>", [[<C-\><C-n>]], { silent = true, desc = "Terminal: normal mode" })
    -- From Normal (while in a terminal buffer), jump back into insert
    map("n", "<A-CR>", function()
      if vim.bo.buftype == "terminal" then vim.cmd("startinsert") end
    end, { silent = true, desc = "Terminal: re-enter insert" })

    --------------------------------------------------------------------------
    -- Navigate between panes/tmux from terminal buffers too (Ctrl-h/j/k/l)
    --------------------------------------------------------------------------
    do
      local ok, n = pcall(require, "nvim-tmux-navigation")
      if ok then
        local nopts = { silent = true }
        map("t", "<C-h>", n.NvimTmuxNavigateLeft,  nopts)
        map("t", "<C-j>", n.NvimTmuxNavigateDown,  nopts)
        map("t", "<C-k>", n.NvimTmuxNavigateUp,    nopts)
        map("t", "<C-l>", n.NvimTmuxNavigateRight, nopts)
        map("t", [[<C-\>]], n.NvimTmuxNavigateLastActive, nopts)
      end
    end

    --------------------------------------------------------------------------
    -- Smart resize (works in normal + terminal). Floats resize by config;
    -- splits use :resize / :vertical resize.
    -- Keys: <A-h/j/k/l> = left/down/up/right
    --       <A-=> equalize splits, <A-0> reset float size
    --------------------------------------------------------------------------
    local function is_float(win) return (vim.api.nvim_win_get_config(win).relative or "") ~= "" end
    vim.g._nvterm_float_w = vim.g._nvterm_float_w or 0.84
    vim.g._nvterm_float_h = vim.g._nvterm_float_h or 0.84
    local STEP = 0.04
    local function clamp(x, lo, hi) return math.max(lo, math.min(hi, x)) end

    local function resize_float(win, dx, dy)
      local cfg = vim.api.nvim_win_get_config(win)
      local cols, lines = vim.o.columns, vim.o.lines
      local ch          = vim.o.cmdheight or 1
      local avail_rows  = math.max(1, lines - ch)

      vim.g._nvterm_float_w = clamp(vim.g._nvterm_float_w + dx, 0.50, 0.96)
      vim.g._nvterm_float_h = clamp(vim.g._nvterm_float_h + dy, 0.40, 0.96)

      local W = math.floor(cols       * vim.g._nvterm_float_w)
      local H = math.floor(avail_rows * vim.g._nvterm_float_h)
      cfg.width  = W
      cfg.height = H
      cfg.row    = math.floor((avail_rows - H) / 2)
      cfg.col    = math.floor((cols       - W) / 2)
      vim.api.nvim_win_set_config(win, cfg)
    end

    local function smart_resize_left()
      if is_float(0) then resize_float(0, -STEP, 0) else vim.cmd("vertical resize +2") end
    end
    local function smart_resize_right()
      if is_float(0) then resize_float(0,  STEP, 0) else vim.cmd("vertical resize -2") end
    end
    local function smart_resize_up()
      if is_float(0) then resize_float(0, 0, -STEP) else vim.cmd("resize +1") end
    end
    local function smart_resize_down()
      if is_float(0) then resize_float(0, 0,  STEP) else vim.cmd("resize -1") end
    end
    local function smart_equalize() vim.cmd("wincmd =") end
    local function float_reset()
      vim.g._nvterm_float_w, vim.g._nvterm_float_h = 0.84, 0.84
      if is_float(0) then resize_float(0, 0, 0) end
    end

    local ropts = { silent = true, desc = "Smart resize" }
    map({ "n", "t" }, "<A-h>", smart_resize_left,  ropts)
    map({ "n", "t" }, "<A-j>", smart_resize_down,  ropts)
    map({ "n", "t" }, "<A-k>", smart_resize_up,    ropts)
    map({ "n", "t" }, "<A-l>", smart_resize_right, ropts)
    map({ "n", "t" }, "<A-=>", smart_equalize,     { silent = true, desc = "Equalize splits" })
    map({ "n", "t" }, "<A-0>", float_reset,        { silent = true, desc = "Reset float size" })
  end,
}
