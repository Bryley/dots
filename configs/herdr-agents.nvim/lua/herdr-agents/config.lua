---Configuration for herdr-agents.nvim.

---@class HerdrAgentsSpawnOpts
---@field placement? "split"|"tab"|"workspace" where the new agent pane goes
---@field direction? "right"|"down" split direction when placement is "split"
---@field ratio? number optional split ratio (0..1)
---@field workspace? string workspace id or label for placement = "tab"; created if missing
---@field focus? boolean focus the new agent after spawning
---@field cwd? string working directory for the new pane (default: nvim cwd)
---@field harness? string command that starts the agent harness in the pane
---@field name? string base label for spawned panes/tabs/workspaces
---@field ready_timeout_ms? integer how long to wait for the agent to report idle

---@class HerdrAgentsConfig
---@field herdr_bin string
---@field persist_selection boolean
---@field spawn HerdrAgentsSpawnOpts
---@field agents table<string, HerdrAgentsSpawnOpts> named spawn profiles
---@field send table
---@field notify table

local M = {}

---@type HerdrAgentsConfig
M.defaults = {
  herdr_bin = "herdr",
  persist_selection = true,

  -- Defaults for newly spawned subagents. Named profiles in `agents`
  -- override these per-profile.
  spawn = {
    placement = "split",
    direction = "right",
    ratio = nil,
    workspace = nil,
    focus = false,
    cwd = nil,
    harness = "claude",
    name = "hagent",
    ready_timeout_ms = 30000,
  },

  -- Named spawn profiles, e.g.
  --   agents = { reviewer = { harness = "claude --model opus", placement = "tab" } }
  -- Used by :HerdrAgentSpawn <name>. The profile name becomes the label
  -- unless the profile sets `name` itself.
  agents = {},

  send = {
    -- Ask before sending into an agent that is currently working and was
    -- not spawned by this plugin.
    confirm_if_working = true,
    -- Formats the contextual prompt for :HerdrAgentSend/:HerdrAgentDelegate.
    -- ctx = { prompt, file (absolute; nil for unnamed buffers), line1, line2,
    --         cwd (target agent's working directory; nil when unknown) }
    -- The default prefixes the prompt with the origin, using a path
    -- relative to the agent's cwd when the file lives inside it.
    -- Keep the result single-line: raw newlines may submit early in some
    -- harness TUIs.
    ---@param ctx { prompt: string, file?: string, line1: integer, line2: integer, cwd?: string }
    ---@return string
    context = function(ctx)
      if not ctx.file then
        return ctx.prompt
      end
      local path = ctx.file
      if ctx.cwd and ctx.cwd ~= "" then
        local cwd = (ctx.cwd:gsub("/+$", ""))
        if vim.startswith(path, cwd .. "/") then
          path = path:sub(#cwd + 2)
        end
      end
      local loc
      if ctx.line1 == ctx.line2 then
        loc = tostring(ctx.line1)
      else
        loc = ("%d-%d"):format(ctx.line1, ctx.line2)
      end
      return ("(ran from %s:%s) %s"):format(path, loc, ctx.prompt)
    end,
  },

  notify = {
    on_done = true,
    on_blocked = true,
    -- How long a background status watcher lives after a send.
    watch_timeout_ms = 30 * 60 * 1000,
  },
}

M.options = vim.deepcopy(M.defaults)

---@param opts? table
function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts or {})
end

---Resolve the spawn options for a named profile (or the defaults).
---@param name? string
---@return HerdrAgentsSpawnOpts|nil profile
---@return string|nil err
function M.spawn_profile(name)
  local profile = vim.deepcopy(M.options.spawn)
  if name and name ~= "" then
    local override = M.options.agents[name]
    if not override then
      return nil, ("no configured agent profile %q (see config.agents)"):format(name)
    end
    profile = vim.tbl_deep_extend("force", profile, override)
    if not override.name then
      profile.name = name
    end
  end
  return profile
end

return M
