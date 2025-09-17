-- lua/suhail/lazy/lsp.lua
return {
  "neovim/nvim-lspconfig",
  dependencies = {
    "williamboman/mason.nvim",
    "williamboman/mason-lspconfig.nvim",
    "hrsh7th/cmp-nvim-lsp",
    "hrsh7th/cmp-buffer",
    "hrsh7th/cmp-path",
    "hrsh7th/cmp-cmdline",
    "hrsh7th/nvim-cmp",
    "L3MON4D3/LuaSnip",
    "saadparwaiz1/cmp_luasnip",
    -- "j-hui/fidget.nvim", -- optional; we guard it below
  },
  config = function()
    local lspconfig = require("lspconfig")
    local cmp       = require("cmp")
    local cmp_lsp   = require("cmp_nvim_lsp")

    -- guard fidget (in case you keep it commented out)
    do
      local ok, fidget = pcall(require, "fidget")
      if ok then fidget.setup({}) end
    end

    local capabilities = vim.tbl_deep_extend(
      "force",
      {},
      vim.lsp.protocol.make_client_capabilities(),
      cmp_lsp.default_capabilities()
    )

    require("mason").setup()
    require("mason-lspconfig").setup({
      automatic_installation = false, -- correct key
      ensure_installed = { "lua_ls", "pylsp", "ts_ls", "rust_analyzer" },
      handlers = {
        -- Default: set ALL servers to autostart=false
        function(server)
          lspconfig[server].setup({
            capabilities = capabilities,
            autostart = false,
          })
        end,

        ["lua_ls"] = function()
          lspconfig.lua_ls.setup({
            capabilities = capabilities,
            autostart = false,
            settings = { Lua = { diagnostics = { globals = { "vim" } } } },
          })
        end,

        ["pylsp"] = function()
          lspconfig.pylsp.setup({
            capabilities = capabilities,
            autostart = false,
            settings = {
              pylsp = {
                plugins = {
                  ruff        = { enabled = false }, -- we use CLI Ruff on-demand
                  flake8      = { enabled = false },
                  mccabe      = { enabled = false },
                  pycodestyle = { enabled = false },
                  pyflakes    = { enabled = false },
                  yapf        = { enabled = false },
                },
              },
            },
          })
        end,
      },
    })

    -- cmp setup
    local cmp_select = { behavior = cmp.SelectBehavior.Select }
    cmp.setup({
      snippet = { expand = function(args) require("luasnip").lsp_expand(args.body) end },
      mapping = cmp.mapping.preset.insert({
        ["<C-p>"] = cmp.mapping.select_prev_item(cmp_select),
        ["<C-n>"] = cmp.mapping.select_next_item(cmp_select),
        ["<C-y>"] = cmp.mapping.confirm({ select = true }),
        ["<C-Space>"] = cmp.mapping.complete(),
      }),
      sources = cmp.config.sources(
        { { name = "nvim_lsp" }, { name = "luasnip" } },
        { { name = "buffer" } }
      ),
    })

    -- diagnostics UI; start disabled
    vim.diagnostic.config({
      virtual_text = true,
      signs = true,
      underline = true,
      update_in_insert = false,
      float = {
        focusable = false,
        style = "minimal",
        border = "rounded",
        source = "always",
        header = "",
        prefix = "",
      },
    })
    vim.schedule(function() vim.diagnostic.enable(false) end)

    --------------------------------------------------------------------------
    -- LSP mute + toggles (kept INSIDE config so there’s no code after `return`)
    --------------------------------------------------------------------------
    vim.g.lsp_muted = true

    local function stop_clients(bufnr, name)
      bufnr = bufnr or 0
      local list = {}
      if vim.lsp.get_clients then
        list = vim.lsp.get_clients({ bufnr = bufnr, name = name })
      else
        for _, c in ipairs(vim.lsp.get_active_clients()) do
          if (not name or c.name == name) and c.attached_buffers and c.attached_buffers[bufnr] then
            table.insert(list, c)
          end
        end
      end
      for _, c in ipairs(list) do c.stop(true) end
    end

    vim.api.nvim_create_autocmd("LspAttach", {
      callback = function(args)
        if not vim.g.lsp_muted then return end
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if client then vim.schedule(function() client.stop(true) end) end
      end,
    })

    vim.api.nvim_create_user_command("LspOn", function(opts)
      vim.g.lsp_muted = false
      vim.diagnostic.enable(true, { bufnr = 0 })
      if opts.args ~= "" then
        vim.cmd("LspStart " .. opts.args)   -- e.g. :LspOn rust_analyzer
      else
        -- Optional hook to lazy-load fidget or others on demand:
        pcall(vim.api.nvim_exec_autocmds, "User", { pattern = "LspOn" })
        vim.cmd("LspStart")                 -- start whatever applies to this buffer
      end
    end, { nargs = "?" })

    vim.api.nvim_create_user_command("LspOff", function()
      vim.g.lsp_muted = true
      vim.diagnostic.enable(false)
      for _, b in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(b) then stop_clients(b) end
      end
    end, {})
  end,
}
