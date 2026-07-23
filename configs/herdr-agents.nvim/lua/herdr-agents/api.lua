---Herdr agent API: list, spawn, select, send, and fetch responses.
---
---All functions are asynchronous and take a callback as their last
---argument; callbacks run on the main loop.

local cli = require("herdr-agents.cli")
local config = require("herdr-agents.config")
local response = require("herdr-agents.response")
local selection = require("herdr-agents.selection")

local M = {}

---@class HerdrAgent
---@field pane_id string
---@field agent string|nil detected harness, e.g. "claude", "pi"
---@field status string "idle"|"working"|"blocked"|"done"|"unknown"
---@field label string|nil pane label, if renamed
---@field cwd string
---@field tab_id string
---@field workspace_id string
---@field focused boolean
---@field session table|nil harness session info reported by herdr
---@field managed boolean spawned by this plugin

local state = {
  ---@type string|nil currently selected agent pane id
  selected = nil,
  ---@type HerdrAgent|nil cached metadata for the selected agent
  selected_agent = nil,
  ---@type table<string, boolean> pane ids spawned by this plugin
  managed = {},
  ---@type integer suffix counter for spawned agent labels
  counter = 0,
  ---@type table<string, vim.SystemObj[]> background status watchers per pane
  watchers = {},
  ---@type table<string, integer> watcher generation per pane (stale-callback guard)
  watch_gen = {},
}

M._state = state

---@param p table raw pane object from the herdr CLI
---@return HerdrAgent
local function to_agent(p)
  return {
    pane_id = p.pane_id,
    agent = p.agent,
    status = p.agent_status or "unknown",
    label = p.label,
    cwd = p.cwd,
    tab_id = p.tab_id,
    workspace_id = p.workspace_id,
    focused = p.focused or false,
    session = p.agent_session,
    managed = state.managed[p.pane_id] or false,
  }
end

---List panes with a detected agent (excluding nvim's own pane).
---@param cb fun(err: string|nil, agents: HerdrAgent[]|nil)
function M.list_agents(cb)
  cli.call({ "pane", "list" }, function(err, res)
    if err then
      return cb(err)
    end
    local own = vim.env.HERDR_PANE_ID
    local agents = {}
    for _, p in ipairs(res.panes or {}) do
      if p.pane_id ~= own and (p.agent or state.managed[p.pane_id]) then
        agents[#agents + 1] = to_agent(p)
      end
    end
    cb(nil, agents)
  end)
end

---@param pane_id string
---@param cb fun(err: string|nil, agent: HerdrAgent|nil)
function M.get_agent(pane_id, cb)
  cli.call({ "pane", "get", pane_id }, function(err, res)
    if err then
      return cb(err)
    end
    cb(nil, to_agent(res.pane))
  end)
end

---Select an agent pane as the target for sends.
---@param pane_id string|nil nil clears the selection
function M.select(pane_id)
  state.selected = pane_id
  state.selected_agent = nil

  if not pane_id then
    selection.clear()
    vim.cmd("redrawstatus")
    return
  end

  selection.set(pane_id)
  M.get_agent(pane_id, function(err, agent)
    if err and state.selected == pane_id then
      state.selected = nil
      selection.clear()
    elseif state.selected == pane_id then
      state.selected_agent = agent
    end
    vim.cmd("redrawstatus")
  end)
end

---Restore the selection saved for the current Neovim working directory.
---Keeps the saved value when Herdr is unavailable; clears it if its pane is gone.
function M.restore_selection()
  local pane_id = selection.get()
  if not pane_id then
    return
  end

  local available = cli.available()
  if not available then
    return
  end

  M.get_agent(pane_id, function(err)
    if err then
      selection.clear()
      return
    end
    M.select(pane_id)
  end)
end

---@return string|nil pane_id
function M.selected()
  return state.selected
end

---@return HerdrAgent|nil
function M.selected_agent()
  return state.selected_agent
end

---Wait for one of several agent statuses; first match wins.
---@param pane_id string
---@param statuses string[]
---@param timeout_ms integer
---@param cb fun(err: string|nil, status: string|nil)
---@return vim.SystemObj[] handles the in-flight waiters (for cancellation)
local function race_status(pane_id, statuses, timeout_ms, cb)
  local handles = {}
  local settled = false
  local failed = 0
  for _, status in ipairs(statuses) do
    local h
    h = cli.call(
      { "agent", "wait", pane_id, "--until", status, "--timeout", tostring(timeout_ms) },
      function(err)
        if settled then
          return
        end
        if err then
          failed = failed + 1
          if failed == #statuses then
            settled = true
            cb(("agent %s did not reach %s within %dms"):format(
              pane_id, table.concat(statuses, "/"), timeout_ms))
          end
          return
        end
        settled = true
        for _, other in ipairs(handles) do
          if other ~= h then
            pcall(other.kill, other, 15)
          end
        end
        cb(nil, status)
      end
    )
    if h then
      handles[#handles + 1] = h
    end
  end
  return handles
end

---Resolve a workspace spec (id or label) to a workspace id.
---Creates the workspace when no match exists; in that case the fresh
---workspace's root pane id is also returned so it can be reused directly.
---@param spec string|nil
---@param cb fun(err: string|nil, ws_id: string|nil, root_pane_id: string|nil)
local function resolve_workspace(spec, cb)
  if not spec then
    return cb(nil, nil, nil) -- current workspace
  end
  cli.call({ "workspace", "list" }, function(err, res)
    if err then
      return cb(err)
    end
    for _, ws in ipairs(res.workspaces or {}) do
      if ws.workspace_id == spec or ws.label == spec then
        return cb(nil, ws.workspace_id, nil)
      end
    end
    cli.call({ "workspace", "create", "--label", spec, "--no-focus" }, function(cerr, cres)
      if cerr then
        return cb(cerr)
      end
      cb(nil, cres.workspace.workspace_id, cres.root_pane.pane_id)
    end)
  end)
end

---Spawn a temporary agent per the configured defaults or a named profile.
---The new agent is marked managed and selected as soon as its pane exists;
---the callback fires once the harness reports ready (agent_status idle).
---@param name? string|HerdrAgentsSpawnOpts profile name, or option overrides
---@param cb? fun(err: string|nil, agent: HerdrAgent|nil, warn: string|nil)
function M.spawn(name, cb)
  cb = cb or function() end
  local profile, perr = config.spawn_profile(type(name) == "string" and name or nil)
  if not profile then
    return cb(perr)
  end
  if type(name) == "table" then
    profile = vim.tbl_deep_extend("force", profile, name)
  end

  state.counter = state.counter + 1
  local label = ("%s-%d"):format(profile.name, state.counter)
  local cwd = profile.cwd or vim.fn.getcwd()
  local focus_flag = profile.focus and "--focus" or "--no-focus"

  local function on_pane(pane_id)
    state.managed[pane_id] = true
    M.select(pane_id)
    cli.call({ "pane", "rename", pane_id, label }, function() end)
    cli.call({ "pane", "run", pane_id, profile.harness }, function(rerr)
      if rerr then
        return cb("failed to start harness: " .. rerr)
      end
      local timeout = profile.ready_timeout_ms or 30000
      cli.call(
        { "agent", "wait", pane_id, "--until", "idle", "--timeout", tostring(timeout) },
        function(werr)
          M.get_agent(pane_id, function(_, agent)
            agent = agent or { pane_id = pane_id, label = label, managed = true }
            if state.selected == pane_id then
              state.selected_agent = agent
              vim.cmd("redrawstatus")
            end
            if werr then
              cb(nil, agent, ("agent %s (%s) has not reported ready after %dms"):format(
                label, pane_id, timeout))
            else
              cb(nil, agent)
            end
          end)
        end
      )
    end)
  end

  if profile.placement == "split" then
    local args = { "pane", "split", "--current", "--direction", profile.direction or "right",
      focus_flag, "--cwd", cwd }
    if profile.ratio then
      vim.list_extend(args, { "--ratio", tostring(profile.ratio) })
    end
    cli.call(args, function(err, res)
      if err then
        return cb(err)
      end
      on_pane(res.pane.pane_id)
    end)
  elseif profile.placement == "tab" then
    resolve_workspace(profile.workspace, function(err, ws_id, fresh_root_pane)
      if err then
        return cb(err)
      end
      if fresh_root_pane then
        -- Brand-new workspace: use its root pane instead of adding a tab.
        return on_pane(fresh_root_pane)
      end
      local args = { "tab", "create", "--label", label, focus_flag, "--cwd", cwd }
      if ws_id then
        vim.list_extend(args, { "--workspace", ws_id })
      end
      cli.call(args, function(cerr, res)
        if cerr then
          return cb(cerr)
        end
        on_pane(res.root_pane.pane_id)
      end)
    end)
  elseif profile.placement == "workspace" then
    local args = { "workspace", "create", "--label", profile.workspace or label,
      "--cwd", cwd, focus_flag }
    cli.call(args, function(err, res)
      if err then
        return cb(err)
      end
      on_pane(res.root_pane.pane_id)
    end)
  else
    cb(("invalid spawn placement %q (expected split|tab|workspace)"):format(
      tostring(profile.placement)))
  end
end

---Notify when an agent finishes or gets blocked after a send.
---@param pane_id string
function M.watch(pane_id)
  local ncfg = config.options.notify
  if not (ncfg.on_done or ncfg.on_blocked) then
    return
  end
  local prev = state.watchers[pane_id]
  if prev then
    for _, h in ipairs(prev) do
      pcall(h.kill, h, 15)
    end
    state.watchers[pane_id] = nil
  end
  local gen = (state.watch_gen[pane_id] or 0) + 1
  state.watch_gen[pane_id] = gen

  -- Wait for the agent to pick the prompt up before watching for a
  -- terminal status, otherwise a still-idle agent looks finished.
  local start = cli.call(
    { "agent", "wait", pane_id, "--until", "working", "--timeout", "15000" },
    function(err)
      if state.watch_gen[pane_id] ~= gen then
        return -- superseded by a newer watch
      end
      if err then
        state.watchers[pane_id] = nil
        return
      end
      local statuses = {}
      if ncfg.on_done then
        vim.list_extend(statuses, { "done", "idle" })
      end
      if ncfg.on_blocked then
        statuses[#statuses + 1] = "blocked"
      end
      state.watchers[pane_id] = race_status(
        pane_id, statuses, ncfg.watch_timeout_ms,
        function(rerr, status)
          if state.watch_gen[pane_id] ~= gen then
            return
          end
          state.watchers[pane_id] = nil
          if rerr then
            return
          end
          if status == "blocked" then
            vim.notify(("Herdr agent %s needs input"):format(pane_id), vim.log.levels.WARN)
          else
            vim.notify(("Herdr agent %s finished"):format(pane_id), vim.log.levels.INFO)
          end
        end
      )
    end
  )
  if start then
    state.watchers[pane_id] = { start }
  end
end

---Send text to an agent pane (text + Enter, via `herdr pane run`).
---`text` may be a function; it is called with the resolved target agent
---(so e.g. paths can be made relative to the agent's cwd) and must return
---the text to send.
---@param pane_id string
---@param text string|fun(agent: HerdrAgent): string
---@param opts? { force?: boolean, watch?: boolean } force skips the working-agent confirmation; watch=false skips the done/blocked notification watcher
---@param cb? fun(err: string|nil, agent: HerdrAgent|nil)
function M.send(pane_id, text, opts, cb)
  opts = opts or {}
  cb = cb or function() end
  if not pane_id then
    return cb("no agent pane given")
  end
  M.get_agent(pane_id, function(err, agent)
    if err then
      if state.selected == pane_id then
        M.select(nil)
      end
      return cb("agent unavailable: " .. err)
    end
    if not agent.agent and not agent.managed then
      return cb(("pane %s is not a detected agent pane; refusing to send"):format(pane_id))
    end
    if config.options.send.confirm_if_working
      and agent.status == "working"
      and not agent.managed
      and not opts.force
    then
      local choice = vim.fn.confirm(
        ("Herdr agent %s (%s) is currently working. Send anyway?"):format(
          pane_id, agent.agent or "?"),
        "&Yes\n&No", 2)
      if choice ~= 1 then
        return cb("send cancelled")
      end
    end
    if type(text) == "function" then
      text = text(agent)
    end
    cli.call({ "pane", "run", pane_id, text }, function(serr)
      if serr then
        return cb(serr)
      end
      if opts.watch ~= false then
        M.watch(pane_id)
      end
      cb(nil, agent)
    end)
  end)
end

---Read an agent pane's recent output.
---@param pane_id string
---@param opts? { lines?: integer, source?: string }
---@param cb fun(err: string|nil, text: string|nil)
function M.read(pane_id, opts, cb)
  opts = opts or {}
  cli.call({
    "pane", "read", pane_id,
    "--source", opts.source or "recent-unwrapped",
    "--lines", tostring(opts.lines or 100),
  }, function(err, text)
    cb(err, text)
  end)
end

---Wait for the agent to finish its current task, then read its output.
---@param pane_id string
---@param opts? { timeout_ms?: integer, start_timeout_ms?: integer, lines?: integer }
---@param cb fun(err: string|nil, response: { status: string, text: string }|nil)
function M.fetch_response(pane_id, opts, cb)
  opts = opts or {}
  local timeout = opts.timeout_ms or 120000
  -- Give the agent a moment to start working so an idle agent that has
  -- not yet picked up the prompt does not read as already finished.
  cli.call(
    { "agent", "wait", pane_id, "--until", "working",
      "--timeout", tostring(opts.start_timeout_ms or 5000) },
    function()
      race_status(pane_id, { "done", "idle", "blocked" }, timeout, function(rerr, status)
        if rerr then
          return cb(rerr)
        end
        M.read(pane_id, { lines = opts.lines or 200 }, function(perr, text)
          if perr then
            return cb(perr)
          end
          cb(nil, { status = status, text = text })
        end)
      end)
    end
  )
end

---Snapshot the agent's session transcript position so a later
---`final_response` only sees output produced after this point.
---@param pane_id string
---@param cb fun(err: string|nil, marker: HerdrResponseMarker|nil, agent: HerdrAgent|nil)
function M.response_marker(pane_id, cb)
  M.get_agent(pane_id, function(err, agent)
    if err then
      return cb(err)
    end
    cb(nil, response.marker(agent), agent)
  end)
end

---Read the agent's final response text (last assistant message in its
---session transcript) produced after `marker`.
---
---The transcript can lag the agent status by a moment, so a missing
---response is retried a few times before giving up.
---@param pane_id string
---@param marker? HerdrResponseMarker nil reads the whole session
---@param opts? { attempts?: integer, delay_ms?: integer }
---@param cb fun(err: string|nil, text: string|nil)
function M.final_response(pane_id, marker, opts, cb)
  opts = opts or {}
  local attempts = opts.attempts or 5
  local delay = opts.delay_ms or 300
  local function try(n)
    M.get_agent(pane_id, function(err, agent)
      if err then
        return cb(err)
      end
      local text, ferr = response.final(agent, marker)
      if text then
        return cb(nil, text)
      end
      if n >= attempts then
        return cb(ferr)
      end
      vim.defer_fn(function()
        try(n + 1)
      end, delay)
    end)
  end
  try(1)
end

---Send a prompt and capture the agent's final response for it: marker the
---session, send, wait for the agent to finish, then read the response
---from the transcript.
---
---A blocked agent (waiting on input, e.g. a permission prompt) resolves
---with status "blocked" and no text — unless `on_blocked` is given, in
---which case it is called as a notification hook and the request keeps
---waiting for the agent to be answered and finish.
---@param pane_id string
---@param text string|fun(agent: HerdrAgent): string
---@param opts? { force?: boolean, timeout_ms?: integer, start_timeout_ms?: integer, on_blocked?: fun() }
---@param cb fun(err: string|nil, result: { status: string, text: string|nil }|nil)
function M.request(pane_id, text, opts, cb)
  opts = opts or {}
  local timeout = opts.timeout_ms or 300000

  local function await(marker)
    race_status(pane_id, { "done", "idle", "blocked" }, timeout, function(rerr, status)
      if rerr then
        return cb(rerr)
      end
      if status == "blocked" then
        if not opts.on_blocked then
          return cb(nil, { status = "blocked", text = nil })
        end
        opts.on_blocked()
        -- The agent resumes (working) once the user answers it; then keep
        -- waiting for a terminal status.
        cli.call(
          { "agent", "wait", pane_id, "--until", "working",
            "--timeout", tostring(timeout) },
          function(werr)
            if werr then
              return cb("agent stayed blocked: " .. werr)
            end
            await(marker)
          end
        )
        return
      end
      M.final_response(pane_id, marker, {}, function(ferr, rtext)
        if ferr then
          return cb(ferr)
        end
        cb(nil, { status = status, text = rtext })
      end)
    end)
  end

  M.response_marker(pane_id, function(merr, marker)
    if merr then
      return cb("agent unavailable: " .. merr)
    end
    M.send(pane_id, text, { force = opts.force, watch = false }, function(serr)
      if serr then
        return cb(serr)
      end
      -- Let the agent pick the prompt up first, otherwise a still-idle
      -- agent reads as already finished.
      cli.call(
        { "agent", "wait", pane_id, "--until", "working",
          "--timeout", tostring(opts.start_timeout_ms or 10000) },
        function()
          await(marker)
        end
      )
    end)
  end)
end

---Close a pane (intended for plugin-managed agents whose result has been
---consumed).
---@param pane_id string
---@param cb? fun(err: string|nil)
function M.close(pane_id, cb)
  cb = cb or function() end
  cli.call({ "pane", "close", pane_id }, function(err)
    if not err then
      state.managed[pane_id] = nil
      if state.selected == pane_id then
        M.select(nil)
      end
    end
    cb(err)
  end)
end

return M
