---User commands for herdr-agents.nvim.

local M = {}

local function api()
  return require("herdr-agents.api")
end

local function config()
  return require("herdr-agents.config")
end

local function err_notify(msg)
  vim.notify("herdr-agents: " .. msg, vim.log.levels.ERROR)
end

local function info_notify(msg)
  vim.notify("herdr-agents: " .. msg, vim.log.levels.INFO)
end

---@return boolean ok
local function ensure_available()
  local ok, why = require("herdr-agents.cli").available()
  if not ok then
    err_notify(why)
  end
  return ok
end

---@param a HerdrAgent
---@return string
local function describe(a)
  local cwd = a.cwd and vim.fn.fnamemodify(a.cwd, ":~") or "?"
  return ("%s  %s [%s]  %s"):format(
    a.pane_id, a.label or a.agent or "?", a.status, cwd)
end

---Resolve the lines a command applies to: the Ex range when one was
---given, else an active visual selection (e.g. from a `<Cmd>` mapping,
---which passes no range), else the cursor line.
---@param cmd_opts table user-command opts (range, line1, line2)
---@return integer line1
---@return integer line2
function M._capture_range(cmd_opts)
  if cmd_opts.range and cmd_opts.range > 0 then
    return cmd_opts.line1, cmd_opts.line2
  end
  local mode = vim.fn.mode()
  if mode:match("^[vV\22]") then
    local vline = vim.fn.line("v")
    local cline = vim.fn.line(".")
    return math.min(vline, cline), math.max(vline, cline)
  end
  local l = vim.api.nvim_win_get_cursor(0)[1]
  return l, l
end

---Capture the editor context for Send/Delegate. Must run at command
---invocation, before any prompt dialog: opening `vim.ui.input` leaves
---visual mode and may move focus, so range and file are snapshotted here.
---@param cmd_opts table user-command opts (range, line1, line2)
---@return { file?: string, line1: integer, line2: integer }
local function capture_context(cmd_opts)
  local file = vim.api.nvim_buf_get_name(0)
  local line1, line2 = M._capture_range(cmd_opts)
  return {
    file = file ~= "" and file or nil,
    line1 = line1,
    line2 = line2,
  }
end

---Build the prompt builder for a captured context. The returned function
---formats the prompt once the target agent is known, so paths can be
---relative to its cwd.
---@param prompt string
---@param ctx { file?: string, line1: integer, line2: integer }
---@return fun(agent: HerdrAgent|nil): string
local function with_context(prompt, ctx)
  return function(agent)
    return config().options.send.context({
      prompt = prompt,
      file = ctx.file,
      line1 = ctx.line1,
      line2 = ctx.line2,
      cwd = agent and agent.cwd or nil,
    })
  end
end

---Ask for a prompt when the command got no argument.
---@param arg string
---@param title string
---@param cb fun(text: string)
local function with_prompt(arg, title, cb)
  if arg and arg ~= "" then
    return cb(arg)
  end
  vim.ui.input({ prompt = title }, function(input)
    if input and input ~= "" then
      cb(input)
    end
  end)
end

---@param text string|fun(agent: HerdrAgent): string
local function send_to_selected(text)
  local sel = api().selected()
  if not sel then
    return err_notify("no agent selected — use :HerdrAgentSelect or :HerdrAgentDelegate")
  end
  api().send(sel, text, {}, function(err, agent)
    if err then
      return err_notify(err)
    end
    info_notify("sent to " .. describe(agent))
  end)
end

local function pick_agent()
  api().list_agents(function(err, agents)
    if err then
      return err_notify(err)
    end
    if #agents == 0 then
      return err_notify("no herdr agents detected")
    end
    vim.ui.select(agents, {
      prompt = "Select Herdr agent",
      format_item = describe,
    }, function(choice)
      if choice then
        api().select(choice.pane_id)
        info_notify("selected " .. describe(choice))
      end
    end)
  end)
end

---Resolve a :HerdrAgentSelect argument against the live agent list by pane
---id, pane label, or harness name.
---@param query string
local function select_by_query(query)
  api().list_agents(function(err, agents)
    if err then
      return err_notify(err)
    end
    local matches = {}
    for _, a in ipairs(agents) do
      if a.pane_id == query or a.label == query or a.agent == query then
        matches[#matches + 1] = a
      end
    end
    if #matches == 0 then
      return err_notify(("no agent matching %q"):format(query))
    end
    if #matches == 1 then
      api().select(matches[1].pane_id)
      return info_notify("selected " .. describe(matches[1]))
    end
    vim.ui.select(matches, {
      prompt = ("Multiple agents match %q"):format(query),
      format_item = describe,
    }, function(choice)
      if choice then
        api().select(choice.pane_id)
        info_notify("selected " .. describe(choice))
      end
    end)
  end)
end

local function spawn(name)
  info_notify("spawning agent" .. (name and name ~= "" and (" %q"):format(name) or "") .. "…")
  api().spawn(name ~= "" and name or nil, function(err, agent, warn)
    if err then
      return err_notify(err)
    end
    if warn then
      vim.notify("herdr-agents: " .. warn, vim.log.levels.WARN)
    else
      info_notify("ready: " .. describe(agent))
    end
  end)
end

---Delegate: send to the selected agent, spawning the default subagent
---first when nothing (valid) is selected.
---@param text string|fun(agent: HerdrAgent): string
local function delegate(text)
  local function spawn_then_send()
    info_notify("no agent selected — spawning default subagent…")
    api().spawn(nil, function(err, agent, warn)
      if err then
        return err_notify(err)
      end
      if warn then
        -- Never type into a pane whose harness has not come up: the text
        -- would land in a plain shell.
        return err_notify(warn .. "; prompt not sent")
      end
      api().send(agent.pane_id, text, {}, function(serr, sagent)
        if serr then
          return err_notify(serr)
        end
        info_notify("delegated to " .. describe(sagent))
      end)
    end)
  end

  local sel = api().selected()
  if not sel then
    return spawn_then_send()
  end
  api().get_agent(sel, function(err)
    if err then
      api().select(nil)
      return spawn_then_send()
    end
    send_to_selected(text)
  end)
end

---Complete agent pane ids / labels / harness names for :HerdrAgentSelect.
---@param arglead string
---@return string[]
local function complete_agents(arglead)
  local res = require("herdr-agents.cli").call_sync({ "pane", "list" }, 500)
  if type(res) ~= "table" then
    return {}
  end
  local own = vim.env.HERDR_PANE_ID
  local seen, items = {}, {}
  for _, p in ipairs(res.panes or {}) do
    if p.agent and p.pane_id ~= own then
      for _, cand in ipairs({ p.pane_id, p.label, p.agent }) do
        if cand and not seen[cand] and vim.startswith(cand, arglead) then
          seen[cand] = true
          items[#items + 1] = cand
        end
      end
    end
  end
  return items
end

---@param arglead string
---@return string[]
local function complete_profiles(arglead)
  local items = {}
  for name in pairs(config().options.agents) do
    if vim.startswith(name, arglead) then
      items[#items + 1] = name
    end
  end
  table.sort(items)
  return items
end

function M.register()
  local cmd = vim.api.nvim_create_user_command

  cmd("HerdrAgentSpawn", function(opts)
    if ensure_available() then
      spawn(opts.args)
    end
  end, {
    nargs = "?",
    complete = complete_profiles,
    desc = "Spawn a configured temporary Herdr agent and select it",
  })

  cmd("HerdrAgentSelect", function(opts)
    if not ensure_available() then
      return
    end
    if opts.args ~= "" then
      select_by_query(opts.args)
    else
      pick_agent()
    end
  end, {
    nargs = "?",
    complete = complete_agents,
    desc = "Select a Herdr agent (picker with no argument)",
  })

  cmd("HerdrAgentSend", function(opts)
    if not ensure_available() then
      return
    end
    local ctx = capture_context(opts)
    with_prompt(opts.args, "Herdr prompt: ", function(text)
      send_to_selected(with_context(text, ctx))
    end)
  end, {
    nargs = "*",
    range = true,
    desc = "Send a contextual prompt (file + line/range) to the selected Herdr agent",
  })

  cmd("HerdrAgentSendRaw", function(opts)
    if not ensure_available() then
      return
    end
    with_prompt(opts.args, "Herdr text: ", function(text)
      send_to_selected(text)
    end)
  end, {
    nargs = "*",
    desc = "Send text to the selected Herdr agent without editor context",
  })

  cmd("HerdrAgentDelegate", function(opts)
    if not ensure_available() then
      return
    end
    local ctx = capture_context(opts)
    with_prompt(opts.args, "Herdr prompt: ", function(text)
      delegate(with_context(text, ctx))
    end)
  end, {
    nargs = "*",
    range = true,
    desc = "Send a contextual prompt, spawning the default subagent if none is selected",
  })
end

return M
