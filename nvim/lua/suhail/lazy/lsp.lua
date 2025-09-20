-- lua/suhail/lazy/lsp.lua
return {
  "neovim/nvim-lspconfig",
  dependencies = {
    "williamboman/mason.nvim",
    "williamboman/mason-lspconfig.nvim",
    -- NOTE: no cmp-nvim-lsp here; cmp.lua will bring it
  },
  config = function()
    local lspconfig = require("lspconfig")
    local has = function(bin) return vim.fn.executable(bin) == 1 end

    -- Prefer Pyright/BasedPyright, fallback to pylsp if neither is available.
    local PY_SERVER = (has("pyright-langserver") and "pyright")
                   or (has("basedpyright") and "basedpyright")
                   or "pylsp"

    -- Capabilities: upgrade if cmp is available; otherwise base caps.
    local base_caps = vim.lsp.protocol.make_client_capabilities()
    local capabilities = base_caps
    local ok, cmp_lsp = pcall(require, "cmp_nvim_lsp")
    if ok and cmp_lsp and cmp_lsp.default_capabilities then
      capabilities = cmp_lsp.default_capabilities(base_caps)
    end

    require("mason").setup()
    require("mason-lspconfig").setup({
      automatic_installation = false,
      ensure_installed = { "ruff", PY_SERVER, "rust_analyzer" },
      handlers = {
        -- Default handler: autostart OFF (use :LspOn)
        function(server)
          lspconfig[server].setup({
            capabilities = capabilities,
            autostart = false,
          })
        end,

        -- Ruff (native, spawns `ruff server`): let Pyright own hovers
        ["ruff"] = function()
          lspconfig.ruff.setup({
            capabilities = capabilities,
            autostart = false,
            on_attach = function(client, _)
              client.server_capabilities.hoverProvider = false
            end,
          })
        end,

        -- Pyright (light by default; Ruff handles imports/format)
        ["pyright"] = function()
          lspconfig.pyright.setup({
            capabilities = capabilities,
            autostart = false,
            settings = {
              python = { analysis = { diagnosticMode = "openFilesOnly" } },
              pyright = { disableOrganizeImports = true },
            },
          })
        end,

        -- BasedPyright variant
        ["basedpyright"] = function()
          lspconfig.basedpyright.setup({
            capabilities = capabilities,
            autostart = false,
            settings = {
              basedpyright = { disableOrganizeImports = true },
              python = { analysis = { diagnosticMode = "openFilesOnly" } },
            },
          })
        end,
      },
    })

    --------------------------------------------------------------------------
    -- LSP toggles (opt-in workflow)
    --------------------------------------------------------------------------
    vim.g.lsp_muted = true

    local function stop_clients(bufnr, name)
      bufnr = bufnr or 0
      local list = (vim.lsp.get_clients and vim.lsp.get_clients({ bufnr = bufnr, name = name })) or {}
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
        vim.cmd("LspStart " .. opts.args)      -- e.g. :LspOn ruff | :LspOn pyright
      else
        pcall(vim.api.nvim_exec_autocmds, "User", { pattern = "LspOn" })
        vim.cmd("LspStart")
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
