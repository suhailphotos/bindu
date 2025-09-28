-- lua/suhail/lazy/rust.lua
return {
  {
    "mrcjkb/rustaceanvim",
    version = "^6",         -- Mason 2.0 era; rustaceanvim now recommends v6+
    ft = "rust",
    init = function()
      local function make_dap()
        local cfg = require("rustaceanvim.config")

        -- 1) Find the codelldb binary (installed via Mason or system package)
        local codelldb = vim.fn.exepath("codelldb")
        if codelldb == "" then
          return nil  -- leave nil; rustaceanvim can still auto-detect later if available
        end

        -- 2) Figure out the liblldb location under Mason's new layout
        local sys = (vim.uv or vim.loop).os_uname().sysname
        local ext = (sys == "Linux") and ".so" or ".dylib"
        local mason = vim.fn.expand("$MASON")      -- e.g. ~/.local/share/nvim/mason
        local liblldb = mason ~= "$MASON" and (mason .. "/opt/lldb/lib/liblldb" .. ext) or nil

        -- Only wire DAP when both pieces are resolvable
        if liblldb and (vim.uv or vim.loop).fs_stat(liblldb) then
          return { adapter = cfg.get_codelldb_adapter(codelldb, liblldb) }
        end

        -- Fallback: no explicit adapter; rustaceanvim will try auto-detection.
        return nil
      end

      vim.g.rustaceanvim = {
        server = {
          on_attach = function(_, bufnr)
            local map = function(lhs, rhs, desc)
              vim.keymap.set("n", lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
            end
            map("<leader>rr", function() vim.cmd.RustLsp("runnables") end,   "Rust: runnables")
            map("<leader>rt", function() vim.cmd.RustLsp("testables") end,   "Rust: testables")
            map("<leader>re", function() vim.cmd.RustLsp("expandMacro") end, "Rust: expand macro")
            map("<leader>rf", function() vim.lsp.buf.format({ async = true }) end, "Rust: format buffer")
          end,
          default_settings = {
            ["rust-analyzer"] = {
              check = { command = "clippy" },  -- on-demand style; run when invoked
            },
          },
        },
        dap = make_dap(),  -- may be nil; fine
      }
    end,
  },

  -- Optional: classic rust.vim helpers (no autosave formatting)
  {
    "rust-lang/rust.vim",
    ft = "rust",
    init = function()
      vim.g.rustfmt_autosave = 0
    end,
  },
}
