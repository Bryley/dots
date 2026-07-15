
# Plan

## Step 1 | Herdr API

Add a basic herdr agent API within nvim for quick and easy management with
herdr without having to run clunky herdr CLI commands directly.

Should include simple functions for:

- [x] Listing available agents with metadata (names, ids, harness, etc)
- [x] Sending prompts to the agent
- [x] Recieving/fetching responses from the agent

## Step 2 | Plugin config/setup

- [x] Add setup function with relevant config options that you think will work well. Includes
    - [x] Where to put newly spawned subagents (what workspace, names it should give panes, tabs and workspaces, default harness command)

## Step 3 | Command Interface

- [x] `:HerdrAgentSpawn [name]` — Spawn a configured temporary agent and
  select it. Uses the plugin's configured subagent defaults when no name is
  provided.
- [x] `:HerdrAgentSelect [agent]` — Select an existing Herdr agent. With no
  argument, open a `vim.ui.select` picker.
- [x] `:HerdrAgentSend [prompt]` — Send a contextual prompt to the selected
  agent. Context includes the current file and cursor line, or the supplied
  Ex range. With no prompt, open a native Nvim input prompt.
- [x] `:HerdrAgentSendRaw [text]` — Send text to the selected agent without
  editor context. With no text, open a native Nvim input prompt.
- [x] `:HerdrAgentDelegate [prompt]` — Send a contextual prompt to the
  selected agent. If no agent is selected, spawn the configured subagent,
  select it, then send the prompt.

`Send` and `Delegate` should support Ex ranges, for example:

```vim
:'<,'>HerdrAgentDelegate improve this prose
```

Advanced spawn overrides should remain Lua API/configuration options rather
than Ex command flags in V1.

