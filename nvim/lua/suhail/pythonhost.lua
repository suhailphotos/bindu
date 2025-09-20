-- lua/suhail/pythonhost.lua
local M = {}

local function add(t, v) if v and v ~= "" then t[#t+1] = v end end
local function exepath(p) local x = vim.fn.exepath(p); return (x ~= "" and x) or nil end
local function isExec(p) return p and p ~= "" and vim.fn.executable(p) == 1 end

function M.setup()
  -- if user already pinned it somewhere, respect that
  if vim.g.python3_host_prog and isExec(vim.g.python3_host_prog) then return end

  local c = {}
  -- 1) explicit override (handy if you ever need per-host forcing)
  add(c, vim.env.NVIM_PYTHON_BIN)
  -- 2) your standard: uv-managed host venv
  add(c, vim.fn.expand("~/.venvs/nvim/bin/python"))
  -- 3) conda: current shell env
  add(c, (vim.env.CONDA_PREFIX and (vim.env.CONDA_PREFIX .. "/bin/python")) or nil)
  -- 4) conda: a conventional env name
  add(c, vim.fn.expand("~/.conda/envs/nvim/bin/python"))
  -- 5) last resorts (system/pyenv shims); resolve to absolute
  add(c, exepath("python3"))
  add(c, exepath("python"))

  for _, p in ipairs(c) do
    if isExec(p) then
      vim.g.python3_host_prog = p
      break
    end
  end
end

-- On-demand status (no Python import unless you ask)
function M.status()
  local p = vim.g.python3_host_prog or "(unset)"
  local msg = { "Python host: " .. p }
  if p ~= "(unset)" then table.insert(msg, "Executable: " .. ((isExec(p) and "yes") or "no")) end
  vim.notify(table.concat(msg, "\n"))
end

-- Optional: active check of pynvim only when you run it
function M.check()
  local p = vim.g.python3_host_prog
  if not isExec(p) then
    vim.notify("Python host unset or not executable.", vim.log.levels.WARN)
    return
  end
  vim.system({ p, "-c", "import sys; import pynvim; print(pynvim.__version__)" }, { text = true }, function(res)
    if res.code == 0 then
      vim.schedule(function() vim.notify("pynvim OK: " .. (res.stdout or ""):gsub("%s+$","")) end)
    else
      vim.schedule(function()
        vim.notify(
          "pynvim NOT found in host.\nTip (uv): uv pip install -U --python '" .. p .. "' pynvim",
          vim.log.levels.WARN
        )
      end)
    end
  end)
end

vim.api.nvim_create_user_command("PythonHostStatus", function() M.status() end, {})
vim.api.nvim_create_user_command("PythonHostCheck",  function() M.check()  end, {})

return M
