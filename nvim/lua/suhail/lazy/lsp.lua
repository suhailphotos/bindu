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
    local function has(bin) return vim.fn.executable(bin) == 1 end

    -- Choose your Python LSP: "pyright" (default) or "basedpyright"
    local want = vim.g.py_server or vim.env.NVIM_PY_SERVER or "pyright"
    local PY_SERVER = (want == "basedpyright") and "basedpyright" or "pyright"

    -- Capabilities (upgrade if cmp is available)
    local base_caps = vim.lsp.protocol.make_client_capabilities()
    local capabilities = base_caps
    local ok, cmp_lsp = pcall(require, "cmp_nvim_lsp")
    if ok and cmp_lsp and cmp_lsp.default_capabilities then
      capabilities = cmp_lsp.default_capabilities(base_caps)
    end

    require("mason").setup()
    require("mason-lspconfig").setup({
      automatic_installation = false,
      ensure_installed = { "ruff", PY_SERVER, "rust_analyzer" }, -- no pylsp here
      handlers = {
        -- Default handler: autostart OFF (use :LspOn)
        function(server)
          lspconfig[server].setup({
            capabilities = capabilities,
            autostart = false,
          })
        end,

        -- Ruff (runs `ruff server`); let Pyright/BasedPyright own hovers
        ["ruff"] = function()
          lspconfig.ruff.setup({
            capabilities = capabilities,
            autostart = false,
            on_attach = function(client, _)
              client.server_capabilities.hoverProvider = false
            end,
          })
        end,

        -- Pyright
        ["pyright"] = function()
          lspconfig.pyright.setup({
            capabilities = capabilities,
            autostart = false,
            settings = {
              python = { analysis = { diagnosticMode = "openFilesOnly" } },
              pyright = { disableOrganizeImports = true }, -- Ruff handles imports
            },
          })
        end,

        -- BasedPyright (if you opt into it)
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

    -- Map servers -> binaries for preflight checks
    local bin_for = {
      ruff = "ruff",
      pyright = "pyright-langserver",
      basedpyright = "basedpyright",
      rust_analyzer = "rust-analyzer",
    }

    vim.api.nvim_create_user_command("LspOn", function(opts)
      vim.g.lsp_muted = false
      vim.diagnostic.enable(true, { bufnr = 0 })

      local wanted = {}
      if opts.args ~= "" then
        table.insert(wanted, opts.args)
      else
        wanted = { "ruff", PY_SERVER, "rust_analyzer" }
      end

      local started = 0
      for _, srv in ipairs(wanted) do
        local bin = bin_for[srv]
        if (not bin) or has(bin) then
          local ok2 = pcall(vim.cmd, "LspStart " .. srv)
          if ok2 then started = started + 1 end
        else
          vim.notify(("Skipping %s (missing %s)"):format(srv, bin), vim.log.levels.INFO)
        end
      end

      if started == 0 then
        vim.notify("No LSP servers started (none installed).", vim.log.levels.WARN)
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
