-- --------------------------------------------------
-- notio (Neovim → Notion keymap sync)
-- --------------------------------------------------
return {
  "suhailphotos/notio",
  -- dir = vim.env.MATRIX .. "/nvim/notio", -- local dev version
  name = "notio",
  -- use one of these pinning strategies:
  -- version = "*",                -- tracks latest tag
  version = "v0.1.1",              -- pin to a tag you published
  -- branch = "main",              -- or track a branch (less reproducible)

  dependencies = { "nvim-lua/plenary.nvim" },

  -- don’t load unless the token is present (prevents noisy errors)
  cond = function()
    local k = vim.env.NOTION_API_KEY
    return k ~= nil and k ~= ""
  end,

  opts = {
    database_id = "275a1865-b187-81b9-bc4a-fbe5d44e2911",
    app_page_id = "13fa1865-b187-815a-b3d7-f0a23559e641",
    plugin_pages = {
      ["yazi.nvim"]            = "278a1865-b187-8015-9e18-c51affadd8b1",
      ["telescope.nvim"]       = "278a1865-b187-80ac-9b86-c94087ad60da",
      ["nvim-lspconfig"]       = "278a1865-b187-8013-a3d4-c6b3c29190f1",
      ["nvim-cmp"]             = "278a1865-b187-8050-a679-f32738da7e50",
      ["nvim-tmux-navigation"] = "275a1865-b187-80c9-9aad-f4129638223f",
      ["vim-fugitive"]         = "278a1865-b187-80a3-a5ee-d76871e57751",
      -- add others as needed
    },
    skip_builtins = true,
    skip_prefixes = { "[", "]", "g", "z" },
    skip_plug_mappings = true,
    project_plugins = { ["yazi.nvim"]=true, ["telescope.nvim"]=true },
    update_only = false,
  },

  config = function(_, opts)
    require("notio").setup(opts) -- reads NOTION_API_KEY from env
  end,
}
