---Thin async wrapper around the `herdr` CLI.
---
---All herdr workspace/tab/pane/wait commands talk to the running herdr
---instance over its local unix socket, so calls are fast; `wait ...`
---commands block until their condition and are only ever run async.

local config = require("herdr-agents.config")

local M = {}

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
