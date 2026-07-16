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
---@field response table
---@field inject table

---@class HerdrAgentsInjectCtx
---@field prompt string the user's request
---@field file string|nil absolute path, made relative to the agent's cwd when inside it; nil for unnamed buffers
---@field line1 integer target start line at send time
---@field line2 integer target end line at send time
---@field target string the text being replaced
---@field before string up to `context_lines` lines above the target
---@field after string up to `context_lines` lines below the target
---@field filetype string buffer filetype ("" when unset)

local M = {}

---Fence code so that embedded backtick runs cannot break out.
---@param text string
---@param lang string
---@return string
local function fenced(text, lang)
  local longest = 2
  for run in text:gmatch("`+") do
    longest = math.max(longest, #run)
  end
  local fence = ("`"):rep(longest + 1)
  return ("%s%s\n%s\n%s"):format(fence, lang, text, fence)
end

---Default inject prompt template (see PLAN.md "Example Use").
---@param ctx HerdrAgentsInjectCtx
---@return string
local function inject_prompt(ctx)
  local lines = {
    "INJECT MODE",
    "",
    "You are generating replacement text for a Neovim plugin command.",
    "",
    "Do not edit files.",
    "Do not run formatters.",
    "Do not describe the change.",
    "Do not use markdown fences.",
    "Return ONLY the exact text that should replace the target region.",
    "",
    ("File: %s"):format(ctx.file or "(unnamed buffer)"),
    ("Target range when requested: lines %d-%d"):format(ctx.line1, ctx.line2),
    "The editor tracks the real target location separately, so line numbers are only context.",
    "",
    "User request:",
    ctx.prompt,
    "",
  }
  if ctx.before ~= "" then
    lines[#lines + 1] = "Context before:"
    lines[#lines + 1] = fenced(ctx.before, ctx.filetype)
    lines[#lines + 1] = ""
  end
  lines[#lines + 1] = "Target text to replace:"
  lines[#lines + 1] = fenced(ctx.target, ctx.filetype)
  lines[#lines + 1] = ""
  if ctx.after ~= "" then
    lines[#lines + 1] = "Context after:"
    lines[#lines + 1] = fenced(ctx.after, ctx.filetype)
    lines[#lines + 1] = ""
  end
  lines[#lines + 1] = "Return replacement text only."
  return table.concat(lines, "\n")
end

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

  response = {
    -- Override how an agent's session transcript file is found. Receives
    -- the HerdrAgent and returns a path or nil to fall back to the
    -- built-in resolution (Pi session paths and Claude session ids are
    -- handled out of the box).
    ---@type nil|fun(agent: HerdrAgent): string|nil
    session_file = nil,
  },

  inject = {
    -- Lines of surrounding code sent as context above and below the target.
    context_lines = 20,
    -- How long to wait for the agent to finish an inject request.
    timeout_ms = 300000,
    -- Strip a wrapping markdown fence if the agent returns one anyway.
    strip_fences = true,
    -- Marker shown while the agent works on a region.
    indicator = {
      sign = "󱚝",
      virt_text = "󱚝 herdr agent working…",
    },
    -- Sign-column marker for injected code, cleared with
    -- :HerdrAgentHighlightClear (or automatically after timeout_ms when
    -- set; nil keeps it until cleared).
    highlight = {
      sign = "▎",
      timeout_ms = nil,
    },
    -- Builds the prompt sent to the agent; see HerdrAgentsInjectCtx.
    ---@type fun(ctx: HerdrAgentsInjectCtx): string
    prompt = inject_prompt,
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
