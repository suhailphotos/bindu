-- lua/suhail/pickers/keymaps_from_source.lua
local pickers       = require("telescope.pickers")
local finders       = require("telescope.finders")
local conf          = require("telescope.config").values
local entry_display = require("telescope.pickers.entry_display")
local actions       = require("telescope.actions")
local action_state  = require("telescope.actions.state")

local M = {}

local function dequote(s)
  if not s then return s end
  s = s:gsub("^%s+", ""):gsub("%s+$", "")
  local q = s:sub(1,1)
  if (q == "'" or q == '"') and s:sub(-1) == q then
    return s:sub(2, -2)
  end
  -- [[long string]] (unlikely for lhs, but harmless)
  local l = s:match("^%[%[(.*)%]%]$")
  if l then return l end
  return s
end

-- Split top-level args inside vim.keymap.set(...)
-- We only need the first two (mode, lhs). Handles tables/quotes.
local function first_two_args(line)
  local start_idx = line:find("vim%.keymap%.set%s*%(")
  if not start_idx then return nil end
  local i = line:find("%(", start_idx) + 1
  local depth_brace, in_str = 0, nil
  local esc = false
  local args, cur = {}, {}

  while i <= #line do
    local c = line:sub(i,i)
    if in_str then
      table.insert(cur, c)
      if not esc and c == in_str then
        in_str = nil
      elseif c == "\\" and not esc then
        esc = true
        i = i + 1
        local nextc = line:sub(i,i)
        table.insert(cur, nextc)
        esc = false
      end
    else
      if c == "'" or c == '"' then
        in_str = c
        table.insert(cur, c)
      elseif c == '{' then
        depth_brace = depth_brace + 1
        table.insert(cur, c)
      elseif c == '}' then
        depth_brace = depth_brace - 1
        table.insert(cur, c)
      elseif c == ',' and depth_brace == 0 then
        table.insert(args, table.concat(cur))
        cur = {}
        if #args == 2 then break end
      elseif c == ')' and depth_brace == 0 then
        table.insert(args, table.concat(cur))
        break
      else
        table.insert(cur, c)
      end
    end
    i = i + 1
  end

  -- Ensure we have at least two items
  if #args == 1 then table.insert(args, table.concat(cur)) end
  return args[1], args[2]
end

local function parse_modes(mode_arg)
  if not mode_arg then return "?" end
  mode_arg = mode_arg:gsub("^%s+", ""):gsub("%s+$", "")
  local set = {}
  local order = { 'n','v','x','s','o','i','t','c','l','!' }

  if mode_arg:sub(1,1) == '{' then
    for m in mode_arg:gmatch("[\"']([nvxsoitcl!])[\"']") do
      set[m] = true
    end
  else
    local mstr = dequote(mode_arg) or ""
    for c in mstr:gmatch(".") do set[c] = true end
  end

  local out = {}
  for _, c in ipairs(order) do if set[c] then table.insert(out, c) end end
  return table.concat(out, "")
end

local function make_entry_maker(opts)
  local root = opts.root
  local displayer = entry_display.create({
    separator = "  ",
    items = {
      { width = 28 },          -- "[modes] <lhs>"
      { remaining = true },    -- "path:lnum"
    },
  })

  return function(line)
    -- rg format: path:lnum:col:text
    local filename, lnum, col, text = line:match("^([^:]+):(%d+):(%d+):(.*)$")
    if not filename then return nil end

    local a1, a2 = first_two_args(text)
    local modes  = "[" .. parse_modes(a1) .. "]"
    local lhs    = dequote(a2) or "?"
    local left   = string.format("%s %s", modes, lhs)

    local rel = filename
    if root and filename:sub(1, #root) == root then
      local cut = filename:sub(#root + 2)
      if #cut > 0 then rel = cut end
    end
    local right = string.format("%s:%s", rel, lnum)

    return {
      value    = line,
      display  = displayer({
        { left, "TelescopeResultsIdentifier" },
        right,
      }),
      ordinal  = table.concat({ left, filename, text }, " "),
      filename = filename,
      lnum     = tonumber(lnum),
      col      = tonumber(col),
      text     = text,
    }
  end
end

-- Main picker
function M.keymaps_from_source(opts)
  opts = opts or {}
  if vim.fn.executable("rg") ~= 1 then
    vim.notify("ripgrep (rg) not found in PATH", vim.log.levels.ERROR)
    return
  end

  local root = opts.root or vim.fn.stdpath("config")
  local rg_cmd = {
    "rg",
    "--no-heading", "--with-filename", "--line-number", "--column", "--smart-case",
    "-g", "!**/.git/**",
    "-g", "*.lua",
    -- search for vim.keymap.set( ... ) lines
    "-e", "vim\\.keymap\\.set\\(",
    root,
  }

  pickers.new(opts, {
    prompt_title = "Keymaps (from source)",
    finder       = finders.new_oneshot_job(rg_cmd, { entry_maker = make_entry_maker({ root = root }) }),
    previewer    = conf.grep_previewer(opts),
    sorter       = conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr, map)
      -- default select opens at filename:lnum
      map("i", "<C-y>", function()
        actions.close(prompt_bufnr)
        require("telescope.builtin").keymaps() -- quick hop to runtime keymaps if you want
      end)
      return true
    end,
  }):find()
end

function M.setup()
  vim.keymap.set("n", "<leader>fk", function()
    M.keymaps_from_source()
  end, { desc = "Telescope: find keymaps from source" })
end

return M
