local M = {}

function M.open()
  local ok, telescope = pcall(require, "telescope")
  if not ok then
    vim.notify("Telescope not found", vim.log.levels.ERROR)
    return
  end

  local pickers     = require("telescope.pickers")
  local finders     = require("telescope.finders")
  local conf        = require("telescope.config").values
  local actions     = require("telescope.actions")
  local action_state= require("telescope.actions.state")

  local theme = require("suhail.theme")

  -- Build entries from your families + any extra colorschemes installed
  local families = {}
  for _, name in ipairs(theme.list()) do families[name] = true end

  local entries = {}
  -- 1) your families (authoritative; uses ThemeUse which flips termguicolors)
  for name, _ in pairs(families) do table.insert(entries, { name = name, from = "family" }) end

  -- 2) other installed colorschemes (truecolor; apply directly)
  for _, name in ipairs(vim.fn.getcompletion("", "color")) do
    if not families[name] then
      table.insert(entries, { name = name, from = "colorscheme" })
    end
  end

  table.sort(entries, function(a,b) return a.name < b.name end)

  local orig = {
    name = vim.g.colors_name,
    tgc  = vim.o.termguicolors,
  }
  local previewed -- last previewed name

  local function apply(name, from)
    if from == "family" then
      theme.use(name) -- flips tgc appropriately (mira/nord)
      return
    end
    -- plain colorscheme: assume truecolor
    vim.opt.termguicolors = true
    pcall(vim.cmd.colorscheme, name)
  end

  local function restore()
    vim.opt.termguicolors = orig.tgc
    if orig.name and orig.name ~= "" then
      pcall(vim.cmd.colorscheme, orig.name)
    else
      pcall(vim.cmd.colorscheme, "default")
    end
  end

  pickers.new({}, {
    prompt_title = "Themes",
    finder = finders.new_table({
      results = entries,
      entry_maker = function(item)
        return {
          value = item,
          display = item.name,
          ordinal = item.name,
        }
      end,
    }),
    sorter = conf.generic_sorter({}),
    previewer = false, -- we'll do lightweight live preview
    attach_mappings = function(bufnr, map)
      local function preview_current()
        local entry = action_state.get_selected_entry()
        if not entry then return end
        local name, from = entry.value.name, entry.value.from
        if name ~= previewed then
          apply(name, from)
          previewed = name
        end
      end

      -- confirm = apply and close
      local function confirm()
        local entry = action_state.get_selected_entry()
        if entry then apply(entry.value.name, entry.value.from) end
        actions.close(bufnr)
      end

      -- cancel = restore original and close
      local function cancel()
        restore()
        actions.close(bufnr)
      end

      -- preview while moving
      for _, key in ipairs({ "j", "<Down>" }) do
        map("n", key, function() actions.move_selection_next(bufnr); preview_current() end)
        map("i", key, function() actions.move_selection_next(bufnr); preview_current() end)
      end
      for _, key in ipairs({ "k", "<Up>" }) do
        map("n", key, function() actions.move_selection_previous(bufnr); preview_current() end)
        map("i", key, function() actions.move_selection_previous(bufnr); preview_current() end)
      end

      map("n", "<CR>", confirm); map("i", "<CR>", confirm)
      map("n", "<Esc>", cancel); map("i", "<Esc>", cancel)
      map("n", "<C-c>", cancel); map("i", "<C-c>", cancel)

      -- preview the initially highlighted row
      vim.schedule(preview_current)
      return true
    end,
  }):find()
end

return M
