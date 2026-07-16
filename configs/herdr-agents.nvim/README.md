# herdr-agents.nvim

Neovim integration for dispatching tasks to agents managed by [Herdr](https://herdr.dev).

Requires Neovim 0.12+ and running Neovim inside a Herdr-managed pane
(`HERDR_ENV=1`), with the `herdr` binary on `PATH`.

## Commands

| Command | Description |
| --- | --- |
| `:HerdrAgentSpawn [name]` | Spawn a temporary agent and select it. `name` picks a profile from `config.agents`; without it the `spawn` defaults are used. |
| `:HerdrAgentSelect [agent]` | Select an existing agent by pane id, pane label, or harness name. With no argument, opens a `vim.ui.select` picker. |
| `:HerdrAgentSend [prompt]` | Send a contextual prompt (current file + cursor line, or the supplied Ex range) to the selected agent. With no prompt, opens an input prompt. |
| `:HerdrAgentSendRaw [text]` | Send text to the selected agent without editor context. |
| `:HerdrAgentDelegate [prompt]` | Like `Send`, but spawns and selects the default subagent first when no agent is selected. |
| `:HerdrAgentInject [prompt]` | Replace the range/selection with the selected agent's response. The region is tracked with extmarks, so editing elsewhere while the agent works is safe; injected lines get an orange sign-column mark for review. |
| `:HerdrAgentHighlightClear [--all]` | Clear the injected-code mark under the cursor, or all marks in the buffer with `--all`. |

`Send`, `Delegate`, and `Inject` accept ranges:

```vim
:'<,'>HerdrAgentDelegate improve this prose
:'<,'>HerdrAgentInject implement this function
```

Without an Ex range, an active visual selection is used (so `<Cmd>`-style
visual-mode mappings work too); otherwise the cursor line. The range is
snapshotted before the input dialog opens.

## Setup

Calling `setup` is optional — commands are registered on load and defaults
work out of the box. All keys shown with their defaults:

```lua
require("herdr-agents").setup({
  herdr_bin = "herdr",
  persist_selection = true,  -- restore selected pane per Nvim cwd

  -- Defaults for spawned subagents.
  spawn = {
    placement = "split",       -- "split" | "tab" | "workspace"
    direction = "right",       -- split direction when placement = "split"
    ratio = nil,               -- optional split ratio (0..1)
    workspace = nil,           -- workspace id/label for placement = "tab";
                               -- created (and used directly) if missing
    focus = false,             -- jump to the new agent after spawning
    cwd = nil,                 -- default: nvim's cwd
    harness = "claude",        -- command that starts the agent
    name = "hagent",           -- label base; panes become "hagent-1", …
    ready_timeout_ms = 30000,  -- wait for the agent to report ready
  },

  -- Named spawn profiles for :HerdrAgentSpawn <name>. Each inherits from
  -- `spawn`; the profile key becomes the label unless `name` is set.
  agents = {
    -- reviewer = { harness = "claude --model opus", placement = "tab" },
  },

  send = {
    confirm_if_working = true, -- confirm before interrupting a working,
                               -- non-plugin-managed agent
    context = function(ctx)    -- format contextual prompts; keep the result
      -- ctx = { prompt, file (absolute; nil for unnamed buffers), line1,
      --         line2, cwd (target agent's cwd; nil when unknown) }
      -- single-line: raw newlines may submit early in some harness TUIs.
      -- default: "(ran from <path>:<l1>[-<l2>]) <prompt>" where <path> is
      -- relative to the agent's cwd when the file is inside it, else absolute
    end,
  },

  notify = {
    on_done = true,            -- notify when a prompted agent finishes
    on_blocked = true,         -- notify when it needs input
    watch_timeout_ms = 30 * 60 * 1000,
  },

  response = {
    session_file = nil,        -- fun(agent): path|nil — override how the
                               -- harness session transcript is found; Pi
                               -- session paths and Claude session ids are
                               -- resolved out of the box
  },

  inject = {
    context_lines = 20,        -- code context sent above/below the target
    timeout_ms = 300000,       -- how long to wait for the agent's response
    strip_fences = true,       -- unwrap a markdown fence in the response
    indicator = {              -- shown while the agent works on the region
      sign = "󱚝",
      virt_text = "󱚝 herdr agent working…",
    },
    highlight = {              -- injected-code mark in the sign column
      sign = "▎",
      timeout_ms = nil,        -- nil keeps it until :HerdrAgentHighlightClear
    },
    prompt = function(ctx)     -- builds the INJECT MODE prompt
      -- ctx = { prompt, file (relative to the agent's cwd when inside it),
      --         line1, line2, target, before, after, filetype }
      -- default: strict replace-only template with fenced context blocks
    end,
  },
})
```

Highlight groups `HerdrAgentsWorking` and `HerdrAgentsInjected` (both
default to orange) style the indicator and injected-code marks.

## Lua API

Everything is asynchronous; callbacks run on the main loop.

```lua
local herdr = require("herdr-agents")

herdr.list_agents(function(err, agents) end)   -- HerdrAgent[]: pane_id, agent, status, label, cwd, …
herdr.get_agent(pane_id, function(err, agent) end)
herdr.spawn(name_or_opts, function(err, agent, warn) end)  -- marks managed + selects
herdr.select(pane_id)                          -- nil clears
herdr.selected()                               -- -> pane_id|nil
herdr.selected_agent()                         -- -> cached HerdrAgent|nil
herdr.send(pane_id, text, { force = false }, function(err, agent) end)
herdr.read(pane_id, { lines = 100 }, function(err, text) end)
herdr.fetch_response(pane_id, { timeout_ms = 120000 }, function(err, res) end)  -- res = { status, text (screen scrape) }
herdr.close(pane_id, function(err) end)        -- for consumed managed workers

-- v2: exact final-response capture from the harness's own session
-- transcript (Pi session paths and Claude session ids supported).
herdr.response_marker(pane_id, function(err, marker) end)
herdr.final_response(pane_id, marker, {}, function(err, text) end)
herdr.request(pane_id, text, { timeout_ms = 300000, on_blocked = function() end },
  function(err, res) end)                      -- send → wait → res = { status, text }
```

Safety guardrails:

- Refuses to send into panes that are not detected agents (unless
  plugin-managed), so prompts never land in a plain shell.
- Confirms before sending into a working agent the plugin did not spawn.
- `Delegate` never sends to a freshly spawned pane whose harness failed to
  report ready.

## Development

Run the smoke test:

```sh
nvim --headless -u NONE -l tests/smoke.lua
```

## Intended direction

- Dispatch prompts from Neovim to existing or temporary Herdr agents.
- Surface agent status and attention requests in Neovim.
- Start simple: agents edit normally; reviewable isolated patch workflows are a later iteration.
