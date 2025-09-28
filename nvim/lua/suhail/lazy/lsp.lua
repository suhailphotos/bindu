-- lua/suhail/lazy/lsp.lua
return {
  "neovim/nvim-lspconfig",
  dependencies = {
    { "mason-org/mason.nvim",           opts = {} },
    { "mason-org/mason-lspconfig.nvim", opts = { ensure_installed = { "pyright", "ruff", "rust_analyzer", "lua_ls" } } },
  },
  config = function()
    -- Capabilities (nvim-cmp integration)
    local caps = vim.lsp.protocol.make_client_capabilities()
    local ok, cmp_lsp = pcall(require, "cmp_nvim_lsp")
    if ok and cmp_lsp and cmp_lsp.default_capabilities then
      caps = cmp_lsp.default_capabilities(caps)
    end

    -- Buffer-local keymaps when a server attaches (explicit so K always works)
    local function on_attach(_, bufnr)
      local function map(mode, lhs, rhs, desc)
        vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
      end
      map("n", "K",  vim.lsp.buf.hover,           "LSP Hover")
      map("i", "<C-k>", vim.lsp.buf.signature_help, "Signature Help")
      map("n", "gd", vim.lsp.buf.definition,      "Go to Definition")
      map("n", "gD", vim.lsp.buf.declaration,     "Go to Declaration")
      map("n", "gi", vim.lsp.buf.implementation,  "Go to Implementation")
      map("n", "gr", vim.lsp.buf.references,      "References")
      map("n", "<leader>rn", vim.lsp.buf.rename,  "Rename Symbol")
      map("n", "<leader>ca", vim.lsp.buf.code_action, "Code Action")
    end

    -- Apply defaults to all servers
    vim.lsp.config("*", {
      capabilities = caps,
      on_attach = on_attach,
    })

    -- Lua: teach the server about the global `vim`
    vim.lsp.config("lua_ls", {
      settings = {
        Lua = {
          diagnostics = { globals = { "vim" } },
          workspace   = { library = vim.api.nvim_get_runtime_file("", true), checkThirdParty = false },
          telemetry   = { enable = false },
        },
      },
    })

    -- Ruff: let Pyright/Rust own hover docs
    vim.lsp.config("ruff", {
      on_attach = function(client, bufnr)
        client.server_capabilities.hoverProvider = false
        on_attach(client, bufnr)
      end,
    })

    -- Disable pylsp by default
    vim.lsp.config("pylsp", { enabled = false })

    -- Enable servers (autostart on matching filetypes)
    vim.lsp.enable("pyright")
    vim.lsp.enable("ruff")
    -- vim.lsp.enable("rust_analyzer")
    vim.lsp.enable("lua_ls")

    -- Nicer hover window, still minimal
    vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
      border = "rounded",
      max_width = 88,
      max_height = 24,
      focusable = true,
    })

    --------------------------------------------------------------------------
    -- Diagnostics: QUIET by default + simple controls
    --------------------------------------------------------------------------
    local function set_diag(on)
      vim.diagnostic.config({
        virtual_text = on or false,
        signs        = on or false,
        underline    = on or false,
        update_in_insert = false,
        float = { border = "rounded", source = "if_many" },
      })
    end

    set_diag(false)  -- default OFF

    vim.api.nvim_create_user_command("DiagOn",     function() set_diag(true)  print("Diagnostics ON")  end, {})
    vim.api.nvim_create_user_command("DiagOff",    function() set_diag(false) print("Diagnostics OFF") end, {})
    vim.api.nvim_create_user_command("DiagToggle", function()
      local cfg = vim.diagnostic.config()
      local on = not (cfg.virtual_text or cfg.signs or cfg.underline)
      set_diag(on)
      print("Diagnostics " .. (on and "ON" or "OFF"))
    end, {})
    -- Keymaps for diagnostics control (global)
    vim.keymap.set("n", "<leader>lt", "<cmd>DiagToggle<CR>", { desc = "Diagnostics: Toggle", silent = true })
    vim.keymap.set("n", "<leader>l1", "<cmd>DiagOn<CR>",     { desc = "Diagnostics: On",     silent = true })
    vim.keymap.set("n", "<leader>l0", "<cmd>DiagOff<CR>",    { desc = "Diagnostics: Off",    silent = true })
    vim.keymap.set("n", "<leader>lh", "<cmd>DiagHere<CR>",   { desc = "Diagnostics: Here",   silent = true })

    -- Peek diagnostics at cursor without turning them on
    vim.api.nvim_create_user_command("DiagHere", function()
      vim.diagnostic.open_float(0, { scope = "cursor", border = "rounded", focusable = true })
    end, {})
  end,
}
