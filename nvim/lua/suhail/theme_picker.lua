-- lua/suhail/theme_picker.lua
local M = {}

local function apply(name, from)
  local theme = require("suhail.theme")
  vim.cmd("hi clear")  -- clear first for both paths

  if from == "family" then
    theme.use(name)    -- this now resets rose-pine’s variant via theme.lua
    return
  end

  -- plain colorscheme preview
  vim.opt.termguicolors = true
  pcall(vim.cmd.colorscheme, name)
end

-- Ensure theme plugins are on the rtp so variants (e.g. rose-pine-moon) appear
local function preload_theme_plugins()
  local ok, lazy = pcall(require, "lazy")
  if not ok then return end
  local names = require("suhail.theme").list()  -- e.g. {"mira","nord","rose-pine"}
  pcall(lazy.load, { plugins = names })
end

local function norm(s) return (s:gsub("[_%s]", "-"):lower()) end

local function build_entries()
  local theme = require("suhail.theme")
  local families_norm = {}
  local entries = {}

  -- families first
  for _, n in ipairs(theme.list()) do
    families_norm[norm(n)] = true
    table.insert(entries, { name = n, from = "family" })
  end

  -- add colorschemes that aren't already a family (normalized)
  for _, n in ipairs(vim.fn.getcompletion("", "color")) do
    if not families_norm[norm(n)] then
      table.insert(entries, { name = n, from = "colorscheme" })
    end
  end

  table.sort(entries, function(a, b) return a.name < b.name end)
  return entries
end

-- put this helper near build_entries()
local function find_default_index(entries)
  local current = vim.g.colors_name or ""
  if current == "" then return 1 end

  -- 1) exact match (works for variants like rose-pine-dawn)
  for i, e in ipairs(entries) do
    if e.name == current then return i end
  end

  -- 2) if a variant is active, fall back to the matching family row
  local families = require("suhail.theme").list()
  for _, fam in ipairs(families) do
    if current:find(fam, 1, true) then
      for i, e in ipairs(entries) do
        if e.name == fam and e.from == "family" then return i end
      end
    end
  end

  return 1
end

function M.open()
  preload_theme_plugins()
  local entries = build_entries()

  local orig = { name = vim.g.colors_name, tgc = vim.o.termguicolors }
  local ok_t = pcall(require, "telescope")
  if ok_t then
    local pickers      = require("telescope.pickers")
    local finders      = require("telescope.finders")
    local conf         = require("telescope.config").values
    local actions      = require("telescope.actions")
    local action_state = require("telescope.actions.state")

    local last_previewed, gen = nil, 0
    local function restore()
      vim.opt.termguicolors = orig.tgc
      if orig.name and orig.name ~= "" then pcall(vim.cmd.colorscheme, orig.name)
      else pcall(vim.cmd.colorscheme, "default") end
      last_previewed = nil
    end
    local function schedule_preview(bufnr)
      gen = gen + 1; local mygen = gen
      vim.schedule(function()
        if mygen ~= gen then return end
        local e = action_state.get_selected_entry()
        if not e or not e.value then return end
        local key = e.value.from .. "::" .. e.value.name
        if key == last_previewed then return end
        apply(e.value.name, e.value.from)
        last_previewed = key
      end)
    end

    local default_idx = find_default_index(entries)

    pickers.new({}, {
      prompt_title = "Themes",
      finder = finders.new_table({
        results     = entries,
        entry_maker = function(it) return { value = it, display = it.name, ordinal = it.name } end,
      }),
      sorter = conf.generic_sorter({}),
      previewer = false,
      -- Telescope supports this; if your version doesn’t, we also set it in attach_mappings below.
      default_selection_index = default_idx,
      attach_mappings = function(bufnr, map)
        local function move_then_preview(move_fn)
          return function() move_fn(bufnr); schedule_preview(bufnr) end
        end
        local NEXT, PREV = actions.move_selection_next, actions.move_selection_previous
        for _, k in ipairs({ "j", "<Down>", "<C-n>", "<Tab>", "<C-j>" }) do
          map("n", k, move_then_preview(NEXT)); map("i", k, move_then_preview(NEXT))
        end
        for _, k in ipairs({ "k", "<Up>", "<C-p>", "<S-Tab>", "<C-k>" }) do
          map("n", k, move_then_preview(PREV)); map("i", k, move_then_preview(PREV))
        end

        local function confirm() actions.close(bufnr) end
        local function cancel() restore(); actions.close(bufnr) end
        map("n", "<CR>", confirm); map("i", "<CR>", confirm)
        map("n", "<Esc>", cancel);  map("i", "<Esc>", cancel)
        map("n", "<C-c>", cancel);  map("i", "<C-c>", cancel)

        -- Fallback in case your Telescope build ignores default_selection_index:
        vim.schedule(function()
          local picker = action_state.get_current_picker(bufnr)
          if picker and picker.set_selection then
            pcall(picker.set_selection, picker, default_idx - 1)  -- 0-based
          else
            for _ = 2, default_idx do actions.move_selection_next(bufnr) end
          end
          -- Don’t reapply the same theme as a “preview”
          local e = entries[default_idx]
          last_previewed = e.from .. "::" .. e.name
        end)

        return true
      end,
    }):find()
    return
  end

  -- Fallback (no Telescope): simple selector, no live preview.
  local choices = {}
  for _, e in ipairs(entries) do table.insert(choices, e.name) end
  vim.ui.select(choices, { prompt = "Theme" }, function(choice)
    if not choice then return end
    for _, e in ipairs(entries) do
      if e.name == choice then apply(e.name, e.from); break end
    end
  end)
end

return M
