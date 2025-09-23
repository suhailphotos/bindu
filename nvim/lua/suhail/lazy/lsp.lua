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
        -- Default handler: autostart OFF (use :LspOn or on-demand keys)
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

    -- One-shot allow flag to attach just for a single requested action
    vim.api.nvim_create_autocmd("LspAttach", {
      callback = function(args)
        local bufnr = args.buf
        -- If muted AND not explicitly allowed for this one action, stop.
        if vim.g.lsp_muted and not vim.b[bufnr]._lsp_allow_once then
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if client then vim.schedule(function() client.stop(true) end) end
        end
        -- Clear the one-shot flag after attach
        vim.b[bufnr]._lsp_allow_once = nil
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

    --------------------------------------------------------------------------
    -- (2) On-demand LSP: start server only when you invoke an LSP action
    --------------------------------------------------------------------------
    local function ensure_lsp_then(bufnr, action)
      bufnr = bufnr or 0
      -- Already attached? Just do it.
      if #vim.lsp.get_clients({ bufnr = bufnr }) > 0 then
        action()
        return
      end
      -- Allow a one-time attach for this buffer
      vim.b._lsp_allow_once = true
      -- Run the action once the server attaches
      vim.api.nvim_create_autocmd("LspAttach", {
        buffer = bufnr,
        once = true,
        callback = function()
          action()
        end,
      })
      -- Start any configured servers that match this buffer's filetype
      vim.cmd("LspStart")
    end

    -- Keymap helpers
    local function nmap(lhs, fn, desc)
      vim.keymap.set("n", lhs, fn, { silent = true, desc = desc })
    end
    local function imap(lhs, fn, desc)
      vim.keymap.set("i", lhs, fn, { silent = true, desc = desc })
    end

    -- Quiet-by-default keymaps that wake LSP only when pressed
    nmap("K",  function() ensure_lsp_then(0, vim.lsp.buf.hover) end,               "LSP Hover")
    nmap("gd", function() ensure_lsp_then(0, vim.lsp.buf.definition) end,          "LSP Definition")
    nmap("gD", function() ensure_lsp_then(0, vim.lsp.buf.declaration) end,         "LSP Declaration")
    nmap("gT", function() ensure_lsp_then(0, vim.lsp.buf.type_definition) end,     "LSP Type Def")
    nmap("gi", function() ensure_lsp_then(0, vim.lsp.buf.implementation) end,      "LSP Impl")
    nmap("gr", function() ensure_lsp_then(0, vim.lsp.buf.references) end,          "LSP Refs")
    nmap("<leader>rn", function() ensure_lsp_then(0, vim.lsp.buf.rename) end,      "LSP Rename")
    nmap("<leader>ca", function() ensure_lsp_then(0, vim.lsp.buf.code_action) end, "LSP Code Action")
    imap("<C-k>", function() ensure_lsp_then(0, vim.lsp.buf.signature_help) end,   "Signature help")

    --------------------------------------------------------------------------
    -- Optional: diagnostics stay hidden unless you toggle them
    --------------------------------------------------------------------------
    vim.g._diag_on = false
    vim.diagnostic.config({
      virtual_text = false,
      signs = false,
      underline = false,
      update_in_insert = false,
    })
    vim.api.nvim_create_user_command("DiagToggle", function()
      vim.g._diag_on = not vim.g._diag_on
      vim.diagnostic.config({
        virtual_text = vim.g._diag_on,
        signs = vim.g._diag_on,
        underline = vim.g._diag_on,
      })
      print("Diagnostics " .. (vim.g._diag_on and "ON" or "OFF"))
    end, {})

    --------------------------------------------------------------------------
    -- Optional: Hover on hold (off by default). Clean, no spam.
    --------------------------------------------------------------------------
    local hover_aucmd
    vim.api.nvim_create_user_command("HoverAutoOn", function()
      if hover_aucmd then return end
      hover_aucmd = vim.api.nvim_create_autocmd("CursorHold", {
        callback = function()
          ensure_lsp_then(0, function()
            vim.lsp.buf.hover()
          end)
        end,
      })
      print("Hover-on-hold ON")
    end, {})
    vim.api.nvim_create_user_command("HoverAutoOff", function()
      if hover_aucmd then vim.api.nvim_del_autocmd(hover_aucmd); hover_aucmd = nil end
      print("Hover-on-hold OFF")
    end, {})

    --------------------------------------------------------------------------
    -- (3) Ephemeral mode: stop clients on BufLeave when muted (opt-in)
    --------------------------------------------------------------------------
    vim.g.lsp_ephemeral = false  -- set to true in a session to enable
    vim.api.nvim_create_autocmd("BufLeave", {
      callback = function(args)
        if not vim.g.lsp_muted or not vim.g.lsp_ephemeral then return end
        local bufnr = args.buf
        for _, c in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
          c.stop(true)
        end
      end,
    })
  end,
}
