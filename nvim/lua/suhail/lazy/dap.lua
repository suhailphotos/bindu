-- nvim-dap + UI (on-demand; UI opens only when a session starts)
return {
  {
    "mfussenegger/nvim-dap",
    keys = {
      { "<leader>dc", function() require("dap").continue()        end, desc = "DAP: continue" },
      { "<leader>di", function() require("dap").step_into()       end, desc = "DAP: step into" },
      { "<leader>dj", function() require("dap").step_over()       end, desc = "DAP: step over" },
      { "<leader>dk", function() require("dap").step_out()        end, desc = "DAP: step out" },
      { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "DAP: toggle breakpoint" },
      { "<leader>dd", function()
          local cond = vim.fn.input("Breakpoint condition: ")
          if cond ~= "" then require("dap").set_breakpoint(cond) end
        end, desc = "DAP: conditional breakpoint" },
      { "<leader>dr", function() require("dap").run_last()        end, desc = "DAP: run last" },
      { "<leader>de", function() require("dap").terminate()       end, desc = "DAP: terminate" },
      { "<leader>du", function() require("dapui").toggle()        end, desc = "DAP: toggle UI" },
    },
    config = function()
      -- no adapter here; rustaceanvim wires CodeLLDB when present
    end,
  },
  {
    "rcarriga/nvim-dap-ui",
    dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
    config = function()
      local dap, dapui = require("dap"), require("dapui")
      dapui.setup({})
      -- Auto-open/close UI around sessions
      dap.listeners.before.attach.dapui_cfg       = function() dapui.open() end
      dap.listeners.before.launch.dapui_cfg       = function() dapui.open() end
      dap.listeners.before.event_terminated.dapui_cfg = function() dapui.close() end
      dap.listeners.before.event_exited.dapui_cfg     = function() dapui.close() end
    end,
  },
}
