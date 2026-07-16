---Capture an agent's final response from its harness-native session file.
---
---Screen scraping (`herdr pane read`) includes TUI chrome and wrapping, so
---exact replacement text is instead read from the transcript the harness
---writes on disk. Herdr reports the session reference per pane as
---`agent_session` ({ agent, kind = "path"|"id", value }): Pi reports the
---transcript path directly; Claude Code reports a session id that maps to
---`~/.claude/projects/<munged cwd>/<id>.jsonl`.

local config = require("herdr-agents.config")

local M = {}

---@class HerdrResponseMarker
---@field file string|nil session file at marker time (nil when none existed)
---@field offset integer byte offset to read from

---Claude Code names project directories by replacing every
---non-alphanumeric character of the cwd with "-".
---@param cwd string
---@return string
local function claude_project_dir(cwd)
  return (cwd:gsub("[^%w]", "-"))
end

---Resolve the session transcript file for an agent.
---@param agent HerdrAgent
---@return string|nil path
---@return string|nil err
function M.session_file(agent)
  local hook = config.options.response.session_file
  if hook then
    local path = hook(agent)
    if path then
      return path
    end
  end

  local sess = agent.session
  if not sess or not sess.value then
    return nil, ("agent %s has not reported a harness session"):format(agent.pane_id)
  end

  if sess.kind == "path" then
    return sess.value
  end

  if sess.kind == "id" and sess.agent == "claude" then
    local base = vim.fs.joinpath(vim.uv.os_homedir(), ".claude", "projects")
    local file = sess.value .. ".jsonl"
    if agent.cwd and agent.cwd ~= "" then
      local path = vim.fs.joinpath(base, claude_project_dir(agent.cwd), file)
      if vim.uv.fs_stat(path) then
        return path
      end
    end
    -- The pane cwd can differ from the path claude munged (symlinks,
    -- `cd` after start); session ids are unique, so glob for it.
    local matches = vim.fn.glob(vim.fs.joinpath(base, "*", file), true, true)
    if matches[1] then
      return matches[1]
    end
    return nil, ("no claude session file found for id %s"):format(sess.value)
  end

  return nil, ("unsupported session reference (%s/%s) for agent %s — set config.response.session_file"):format(
    tostring(sess.agent), tostring(sess.kind), agent.pane_id)
end

---Snapshot where the session file currently ends, so a later read only
---sees responses produced after this point. Never fails: a missing or
---unresolvable file simply markers at offset 0.
---@param agent HerdrAgent
---@return HerdrResponseMarker
function M.marker(agent)
  local path = M.session_file(agent)
  if not path then
    return { file = nil, offset = 0 }
  end
  local stat = vim.uv.fs_stat(path)
  return { file = path, offset = stat and stat.size or 0 }
end

---Extract the assistant text of a transcript JSONL entry, or nil.
---Handles both Claude Code ({type = "assistant", message = {...}}) and Pi
---({type = "message", message = {...}}) formats: any entry whose `message`
---has role "assistant" and text content counts. Claude sidechain
---(subagent) entries are skipped.
---@param entry table
---@return string|nil
local function assistant_text(entry)
  if entry.isSidechain then
    return nil
  end
  local msg = entry.message
  if type(msg) ~= "table" or msg.role ~= "assistant" or type(msg.content) ~= "table" then
    return nil
  end
  local texts = {}
  for _, part in ipairs(msg.content) do
    if type(part) == "table" and part.type == "text" and type(part.text) == "string" then
      texts[#texts + 1] = part.text
    end
  end
  if #texts == 0 then
    return nil
  end
  return table.concat(texts, "\n")
end

---Read the agent's final response produced after `marker`.
---
---The final response is the last assistant message with text content; an
---agent that ran tools mid-turn has its intermediate commentary skipped in
---favor of the closing message.
---@param agent HerdrAgent
---@param marker? HerdrResponseMarker nil reads the whole session
---@return string|nil text
---@return string|nil err
function M.final(agent, marker)
  local path, err = M.session_file(agent)
  if not path then
    return nil, err
  end

  -- Only trust the marker offset when it was taken on the same file; a
  -- fresh or rotated session is read from the start.
  local offset = 0
  if marker and marker.file == path then
    offset = marker.offset
  end

  local f = io.open(path, "rb")
  if not f then
    return nil, ("cannot open session file %s"):format(path)
  end
  f:seek("set", offset)
  local data = f:read("*a") or ""
  f:close()

  local last
  for line in data:gmatch("[^\n]+") do
    local ok, entry = pcall(vim.json.decode, line)
    if ok and type(entry) == "table" then
      last = assistant_text(entry) or last
    end
  end
  if not last then
    return nil, "no assistant response in session file after marker"
  end
  return last
end

return M
