-- --------------------------------------------------
-- Telescope (NvChad-style UI + configurable margins/size + pills)
-- --------------------------------------------------
return {
  "nvim-telescope/telescope.nvim",
  version = false,
  cmd = "Telescope",
  dependencies = { "nvim-lua/plenary.nvim" },

  -- === Knobs you can tweak globally (or via :TelescopeUI ...) ===
  init = function()
    -- one simple knob: how much of the screen Telescope should occupy (0–1)
    vim.g.telescope_scale         = vim.g.telescope_scale         or 0.88

    -- keep at least this many cells free on each edge
    vim.g.telescope_padding       = vim.g.telescope_padding       or 10

    -- preview pane fraction (0–1)
    vim.g.telescope_preview_ratio = vim.g.telescope_preview_ratio or 0.55

    -- show a second header bar under the prompt (helps top feel taller)
    vim.g.telescope_results_pill  = (vim.g.telescope_results_pill == nil) and false or vim.g.telescope_results_pill

    -- safety floors (used only if the screen is tiny)
    vim.g.telescope_min_width     = vim.g.telescope_min_width     or 90
    vim.g.telescope_min_height    = vim.g.telescope_min_height    or 24

    -- (optional) separate scales; leave nil to inherit telescope_scale
    vim.g.telescope_width_scale   = vim.g.telescope_width_scale   or nil
    vim.g.telescope_height_scale  = vim.g.telescope_height_scale  or nil
  end,

  -- small helper to compute layout from the knobs above
  keys = (function()
    local function dims()
      local cols, lines = vim.o.columns, vim.o.lines
      local ch          = vim.o.cmdheight or 1
      local pad         = tonumber(vim.g.telescope_padding) or 10
      local minw        = tonumber(vim.g.telescope_min_width) or 90
      local minh        = tonumber(vim.g.telescope_min_height) or 24

      -- available space after padding
      local avail_w_cols = math.max(1, cols  - 2 * pad)
      local avail_h_rows = math.max(1, lines - ch - 2 * pad)

      -- scales (0–1)
      local s  = tonumber(vim.g.telescope_scale) or 0.88
      local ws = tonumber(vim.g.telescope_width_scale)  or s
      local hs = tonumber(vim.g.telescope_height_scale) or s
      local clamp = function(x) return math.max(0.1, math.min(x, 1.0)) end
      ws, hs = clamp(ws), clamp(hs)

      -- convert minima to fractions of the full screen
      local minw_frac = minw / math.max(1, cols)
      local minh_frac = minh / math.max(1, (lines - ch))

      -- also cap by the padding “box”
      local pad_w_frac = avail_w_cols / math.max(1, cols)
      local pad_h_frac = avail_h_rows / math.max(1, (lines - ch))

      local width_frac  = math.max(minw_frac,  math.min(ws, pad_w_frac))
      local height_frac = math.max(minh_frac, math.min(hs, pad_h_frac))

      local preview_ratio = tonumber(vim.g.telescope_preview_ratio) or 0.55  -- fraction (0–1)

      return width_frac, height_frac, preview_ratio
    end

    local function base_layout()
      local wf, hf, pr = dims()
      return {
        sorting_strategy = "ascending",
        layout_strategy  = "horizontal",
        layout_config    = {
          width = wf,                      -- fractions now
          height = hf,                     -- fractions now
          preview_width = pr,              -- fraction (no math needed)
          prompt_position = "top",
          preview_cutoff = 80,
        },
        border = true,                     -- <— titles (“pills”) only render when true
        path_display = { "filename_first" },
      }
    end

    local function with_titles(opts, prompt_title, preview_title)
      opts.prompt_title  = prompt_title
      opts.preview_title = preview_title
      if vim.g.telescope_results_pill then
        opts.results_title = "Results"
      else
        opts.results_title = false
      end
      return opts
    end

    return {
      {
        "<leader>pf",
        function()
          local o = base_layout()
          o.follow, o.hidden = true, true
          require("telescope.builtin").find_files(with_titles(o, "Find Files", "File Preview"))
        end,
        desc = "Files",
      },
      {
        "<C-p>",
        function()
          local o = base_layout()
          o.show_untracked = true
          local ok = pcall(require("telescope.builtin").git_files, with_titles(o, "Git Files", "File Preview"))
          if not ok then
            local f = base_layout()
            f.follow, f.hidden = true, true
            require("telescope.builtin").find_files(with_titles(f, "Find Files", "File Preview"))
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
          local o = base_layout()
          require("telescope.builtin").live_grep(with_titles(o, "Grep", "Grep Preview"))
        end,
        desc = "Grep (live)",
      },
    }
  end)(),

  config = function()
    -- size knobs (change these)
    vim.g.telescope_height_scale = 0.80  -- 0–1, % of available rows after padding
    vim.g.telescope_width_scale  = 0.88  -- optional; leave nil to inherit from scale
    vim.g.telescope_padding      = 2     -- cells kept free on each edge
    vim.g.telescope_min_height   = 28    -- safety floor in rows (optional)
    require("telescope").setup({
      defaults = {
        border = true,                    -- needed for the title “pills”
        winblend = 0,
        dynamic_preview_title = true,
        selection_caret = "▎",
        entry_prefix    = "  ",
        prompt_prefix   = "   ",
        sorting_strategy = "ascending",
        layout_strategy  = "horizontal",
        layout_config    = {
          prompt_position = "top",
          preview_cutoff  = 80,

          -- make size follow your globals even for :Telescope
          width = function(_, cols, _)
            local pad      = tonumber(vim.g.telescope_padding) or 10
            local minw     = tonumber(vim.g.telescope_min_width) or 90
            local scale    = tonumber(vim.g.telescope_width_scale or vim.g.telescope_scale or 0.88)
            local avail    = math.max(1, cols - 2 * pad)
            local by_scale = math.floor(avail * math.max(0.1, math.min(scale, 1.0)))
            return math.max(minw, by_scale)
          end,

          height = function(_, _, lines)
            local ch       = vim.o.cmdheight or 1
            local pad      = tonumber(vim.g.telescope_padding) or 10
            local minh     = tonumber(vim.g.telescope_min_height) or 24
            local scale    = tonumber(vim.g.telescope_height_scale or vim.g.telescope_scale or 0.88)
            local avail    = math.max(1, (lines - ch) - 2 * pad)
            local by_scale = math.floor(avail * math.max(0.1, math.min(scale, 1.0)))
            return math.max(minh, by_scale)
          end,

          -- preview width as a fraction of the picker
          preview_width = tonumber(vim.g.telescope_preview_ratio) or 0.55,
        },
      },
    })

    -- Apply NvChad-like highlight recipe
    local ok, nv = pcall(require, "suhail.ui.telescope_nvchad")
    if ok and type(nv.apply) == "function" then nv.apply() end

    -- Adjust knobs live: :TelescopeUI margin=12 preview=0.6 minh=28 minw=100 results=on|off
    vim.api.nvim_create_user_command("TelescopeUI", function(a)
      for k, v in string.gmatch(a.args or "", "(%w+)=([^%s]+)") do
        if k == "scale"   then vim.g.telescope_scale         = tonumber(v) end
        if k == "padding" then vim.g.telescope_padding       = tonumber(v) end
        if k == "preview" then vim.g.telescope_preview_ratio = tonumber(v) end
        if k == "results" then vim.g.telescope_results_pill  = (v == "on" or v == "true" or v == "1") end
        if k == "minw"    then vim.g.telescope_min_width     = tonumber(v) end
        if k == "minh"    then vim.g.telescope_min_height    = tonumber(v) end
        if k == "ws"      then vim.g.telescope_width_scale   = tonumber(v) end  -- advanced (optional)
        if k == "hs"      then vim.g.telescope_height_scale  = tonumber(v) end  -- advanced (optional)
      end
      vim.notify(("Telescope UI → scale=%.2f, padding=%d, preview=%.2f, results=%s")
        :format(vim.g.telescope_scale, vim.g.telescope_padding,
                vim.g.telescope_preview_ratio, tostring(vim.g.telescope_results_pill)))
    end, { nargs = "*" })
  end,
}
