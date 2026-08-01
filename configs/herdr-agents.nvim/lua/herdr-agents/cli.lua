---Thin async wrapper around the `herdr` CLI.
---
---All herdr workspace/tab/pane/agent commands talk to the running herdr
---instance over its local unix socket, so calls are fast; blocking agent
---wait commands are only ever run async.

local config = require("herdr-agents.config")

local M = {}

-- Herdr 0.7.5+ uses `agent wait --until`; an earlier CLI release used
-- `--status`. Cache the first accepted spelling and retry once when the
-- connected Herdr server reports the other one.
local agent_wait_flag

---True when nvim is running inside a herdr-managed pane and the binary
---is available.
---@return boolean ok
---@return string|nil why not
function M.available()
  if vim.env.HERDR_ENV ~= "1" then
    return false, "nvim is not running inside a herdr-managed pane (HERDR_ENV != 1)"
  end
  if vim.fn.executable(config.options.herdr_bin) ~= 1 then
    return false, ("herdr binary %q not found in PATH"):format(config.options.herdr_bin)
  end
  return true
end

---@param out vim.SystemCompleted
---@return string
local function extract_error(out)
  local msg = out.stderr or ""
  if vim.trim(msg) == "" then
    msg = out.stdout or ""
  end
  msg = vim.trim(msg)
  -- CLI errors print json like {"code":"pane_not_found","message":"..."}
  local ok, obj = pcall(vim.json.decode, msg)
  if ok and type(obj) == "table" and obj.message then
    return obj.message
  end
  if msg == "" then
    return ("herdr exited with code %d"):format(out.code)
  end
  return msg
end

---@param stdout string|nil
---@return table|string|nil
local function decode(stdout)
  if not stdout or stdout == "" then
    return nil
  end
  -- Most commands print {"id":...,"result":{...}}; `pane read` prints text.
  local ok, obj = pcall(vim.json.decode, stdout)
  if ok and type(obj) == "table" and obj.result then
    return obj.result
  end
  return stdout
end

---Run a herdr CLI command asynchronously.
---The callback runs on the main loop (safe for nvim API calls).
---@param args string[] arguments after the binary, e.g. {"pane","list"}
---@param cb fun(err: string|nil, result: table|string|nil)
---@return vim.SystemObj|nil handle nil if the binary could not be spawned
function M.call(args, cb)
  local ok, why = M.available()
  if not ok then
    vim.schedule(function()
      cb(why)
    end)
    return nil
  end
  local cmd = { config.options.herdr_bin }
  vim.list_extend(cmd, args)
  return vim.system(cmd, { text = true }, function(out)
    vim.schedule(function()
      if out.code ~= 0 then
        cb(extract_error(out))
      else
        cb(nil, decode(out.stdout))
      end
    end)
  end)
end

---Wait for an agent state across the compatible Herdr CLI spellings.
---@param pane_id string
---@param status string
---@param timeout_ms integer|string
---@param cb fun(err: string|nil, result: table|string|nil)
---@return vim.SystemObj|nil
function M.agent_wait(pane_id, status, timeout_ms, cb)
  local function args(flag)
    return { "agent", "wait", pane_id, flag, status, "--timeout", tostring(timeout_ms) }
  end
  local flag = agent_wait_flag or "--until"
  return M.call(args(flag), function(err, res)
    if err and err:find("unknown option", 1, true) then
      local fallback = flag == "--until" and "--status" or "--until"
      return M.call(args(fallback), function(retry_err, retry_res)
        if not retry_err then
          agent_wait_flag = fallback
        end
        cb(retry_err, retry_res)
      end)
    end
    if not err then
      agent_wait_flag = flag
    end
    cb(err, res)
  end)
end

---Synchronous variant for contexts that cannot yield (command completion).
---@param args string[]
---@param timeout_ms? integer
---@return table|string|nil result
---@return string|nil err
function M.call_sync(args, timeout_ms)
  local ok, why = M.available()
  if not ok then
    return nil, why
  end
  local cmd = { config.options.herdr_bin }
  vim.list_extend(cmd, args)
  local out = vim.system(cmd, { text = true }):wait(timeout_ms or 1000)
  if out.code ~= 0 then
    return nil, extract_error(out)
  end
  return decode(out.stdout)
end

return M
