
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

## V2 | Inject Mode

Add a `:HerdrAgentInject [prompt]` command for bounded AI replacement at a
specific editor location.

Goals:

- [x] Create the necessary herdr APIs to read the final response from agents,
   or first verify whether the existing API already supports this reliably.
   (Screen scraping is not reliable; instead herdr's `agent_session` pane
   field is resolved to the harness's own session transcript — Pi reports
   the JSONL path directly, Claude reports a session id mapped to
   `~/.claude/projects/<munged cwd>/<id>.jsonl` — and the final assistant
   message is read from there: `response.lua`, `api.request`.)
- [x] Create necessary config options, for instance a setup function config
   option for the inject prompt template using a function to build it. Also a
   config option for how many lines of context to include above and below. Default
   to what is shown below in the "Example Use" section.
   (`config.inject`: `prompt`, `context_lines` (20), `timeout_ms`,
   `strip_fences`, `indicator`, `highlight`; plus `config.response.session_file`.)
- [x] Create the `:HerdrAgentInject [prompt]` command having it send to the
   agent and inject the response using extmarks, making sure it won't inject
   the code in the wrong place even if the line numbers change.
- [x] Add a small orange tinted agent icon/sign or virtual text showing the
   agent is running at that spot. Keep the first pass simple; animations can
   come later. (Sign + eol virtual text, `HerdrAgentsWorking` highlight.)
- [x] Once the code is injected show a temporary orange selection on the
   sidebar indicating that it is AI injected code. Maybe add a
   `:HerdrAgentHighlightClear [--all]` command to clear the selected highlight or
   all highlights in the file with `--all`. (Orange `▎` sign per injected
   line, `HerdrAgentsInjected` highlight, cleared by the command or an
   optional `inject.highlight.timeout_ms`.)

Example Use:

1) User is working on code
2) User starts writing a function stub to do a particular task
3) After writing it the user writes some comments or a `todo!()` macro inside
outlining what the function needs to do and the steps it should take
4) The user runs something like `:'<,'>HerdrAgentInject` while visually selecting the whole function.
5) It opens a prompt window (just like `:HerdrAgentSend`) and the user types something like "Implement this function"
6) The plugin will send something like this to the selected agent:

````text
INJECT MODE

You are generating replacement text for a Neovim plugin command.

Do not edit files.
Do not run formatters.
Do not describe the change.
Do not use markdown fences.
Return ONLY the exact text that should replace the target region.

File: path/to/my/code.rs
Target range when requested: lines 73-75
The editor tracks the real target location separately, so line numbers are only context.

User request:
Implement this function

Context before:
```rust
// nearby code above, if any
```

Target text to replace:
```rust
pub fn fibonacci(num: u32) -> u32 {
    todo!("calculate the fibonacci sequence using num")
}
```

Context after:
```rust
// nearby code below, if any
```

Return replacement text only.
````

7. The editor shows a nice little indicator to the user showing that AI is
   currently working on that spot.
8. The user might safely make additional edits on the same file at different
   areas. Reformatting, renaming variables, adding doccomments, rearranging
   imports etc. As long it is outside of the selection it plans to inject.
9. Once the AI has completed it will inject the response at that location and
   highlight it so it is clear to the user which code was injected so they can review.
10. The user can then clear the selection using `:HerdrAgentHighlightClear`
    while hovering over it.


Implementation note: editor-side tracking/replacement can use Neovim extmarks;
the main feasibility dependency is reliable capture of the agent's final
response text.

