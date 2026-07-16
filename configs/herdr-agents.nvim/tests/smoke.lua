local source = debug.getinfo(1, "S").source:sub(2)
local root = vim.fn.fnamemodify(source, ":h:h")
package.path = root .. "/lua/?.lua;" .. root .. "/lua/?/init.lua;" .. package.path

local plugin = require("herdr-agents")
plugin.setup({
  herdr_bin = "custom-herdr",
  persist_selection = false,
  agents = {
    reviewer = { harness = "claude --model opus", placement = "tab" },
  },
})

assert(plugin.config.herdr_bin == "custom-herdr")
assert(plugin.config.spawn.harness == "claude", "defaults survive setup")

for _, cmd in ipairs({
  "HerdrAgentSpawn",
  "HerdrAgentSelect",
  "HerdrAgentSend",
  "HerdrAgentSendRaw",
  "HerdrAgentDelegate",
  "HerdrAgentInject",
  "HerdrAgentHighlightClear",
}) do
  assert(vim.fn.exists(":" .. cmd) == 2, cmd .. " not defined")
end

-- profile resolution
local config = require("herdr-agents.config")
local prof = assert(config.spawn_profile("reviewer"))
assert(prof.harness == "claude --model opus")
assert(prof.placement == "tab")
assert(prof.name == "reviewer", "profile name defaults to its key")
assert(prof.ready_timeout_ms == 30000, "profile inherits spawn defaults")

local missing, err = config.spawn_profile("nope")
assert(missing == nil and err ~= nil, "unknown profile errors")

-- default profile
local default = assert(config.spawn_profile(nil))
assert(default.harness == "claude" and default.name == "hagent")

-- contextual prompt formatting: origin prefix, path relative to the
-- agent's cwd when inside it, absolute otherwise
local ctx = plugin.config.send.context({
  prompt = "improve this",
  file = "/tmp/proj/lua/x.lua",
  line1 = 3,
  line2 = 9,
  cwd = "/tmp/proj",
})
assert(ctx == "(ran from lua/x.lua:3-9) improve this", ctx)
assert(not ctx:find("\n"), "default context prompt is single-line")

local outside = plugin.config.send.context({
  prompt = "p", file = "/etc/hosts", line1 = 4, line2 = 4, cwd = "/tmp/proj",
})
assert(outside == "(ran from /etc/hosts:4) p", outside)

-- cwd prefix must match whole path components, not partial names
local partial = plugin.config.send.context({
  prompt = "p", file = "/tmp/proj2/x.lua", line1 = 1, line2 = 1, cwd = "/tmp/proj",
})
assert(partial == "(ran from /tmp/proj2/x.lua:1) p", partial)

local no_cwd = plugin.config.send.context({ prompt = "p", file = "/tmp/x.lua", line1 = 4, line2 = 4 })
assert(no_cwd == "(ran from /tmp/x.lua:4) p", no_cwd)

local no_file = plugin.config.send.context({ prompt = "p", line1 = 1, line2 = 1 })
assert(no_file == "p")

-- range capture: Ex range > active visual selection > cursor line
local commands = require("herdr-agents.commands")
vim.cmd("enew")
vim.api.nvim_buf_set_lines(0, 0, -1, false, { "a", "b", "c", "d", "e" })

local l1, l2 = commands._capture_range({ range = 2, line1 = 1, line2 = 3 })
assert(l1 == 1 and l2 == 3, "Ex range wins")

vim.api.nvim_win_set_cursor(0, { 2, 0 })
vim.cmd("normal! V2j")
l1, l2 = commands._capture_range({ range = 0 })
assert(l1 == 2 and l2 == 4, ("visual capture got %d-%d"):format(l1, l2))
vim.cmd("normal! \27")

vim.api.nvim_win_set_cursor(0, { 4, 0 })
vim.cmd("normal! V2k")
l1, l2 = commands._capture_range({ range = 0 })
assert(l1 == 2 and l2 == 4, "reversed visual selection normalizes")
vim.cmd("normal! \27")

vim.api.nvim_win_set_cursor(0, { 5, 0 })
l1, l2 = commands._capture_range({ range = 0 })
assert(l1 == 5 and l2 == 5, "cursor fallback")

-- selection state
local api = require("herdr-agents.api")
assert(api.selected() == nil)
api.select("wX:p9")
assert(api.selected() == "wX:p9")
api.select(nil)
assert(api.selected() == nil)

-- cli availability guard (herdr_bin is fake, HERDR_ENV may not be set)
local cli = require("herdr-agents.cli")
local ok = cli.available()
assert(ok == false, "fake binary must not be available")

-- v2: default inject prompt template
local inject_ctx = {
  prompt = "Implement this function",
  file = "path/to/my/code.rs",
  line1 = 73,
  line2 = 75,
  target = "pub fn fibonacci(num: u32) -> u32 {\n    todo!()\n}",
  before = "// above",
  after = "// below",
  filetype = "rust",
}
local ip = plugin.config.inject.prompt(inject_ctx)
assert(ip:find("INJECT MODE", 1, true), "template header")
assert(ip:find("File: path/to/my/code.rs", 1, true), ip)
assert(ip:find("Target range when requested: lines 73-75", 1, true), ip)
assert(ip:find("User request:\nImplement this function", 1, true), ip)
assert(ip:find("```rust\n// above\n```", 1, true), "context before fenced")
assert(ip:find("```rust\n// below\n```", 1, true), "context after fenced")
assert(ip:find("Return replacement text only.", 1, true))

-- fence grows past backtick runs inside the target
local tricky = plugin.config.inject.prompt(vim.tbl_extend("force", inject_ctx, {
  target = "a\n```\nb\n```",
  before = "",
  after = "",
}))
assert(tricky:find("````rust\na\n```\nb\n```\n````", 1, true), "escalated fence")
assert(not tricky:find("Context before:", 1, true), "empty context omitted")

-- unnamed buffers still produce a template
local unnamed_ctx = vim.deepcopy(inject_ctx)
unnamed_ctx.file = nil
local unnamed = plugin.config.inject.prompt(unnamed_ctx)
assert(unnamed:find("File: (unnamed buffer)", 1, true), unnamed)

-- v2: response session-file resolution + final-response parsing
local response = require("herdr-agents.response")
local tmp = vim.fn.tempname()
vim.fn.mkdir(tmp, "p")

local nofile, rerr = response.session_file({ pane_id = "wX:p1" })
assert(nofile == nil and rerr:find("has not reported"), tostring(rerr))

local session = vim.fs.joinpath(tmp, "session.jsonl")
local pi_agent = {
  pane_id = "wX:p1",
  session = { agent = "pi", kind = "path", value = session },
}
assert(response.session_file(pi_agent) == session, "path sessions resolve directly")

-- config hook wins over built-in resolution
config.options.response.session_file = function()
  return "/hooked.jsonl"
end
assert(response.session_file(pi_agent) == "/hooked.jsonl")
config.options.response.session_file = nil

local function jsonl(entries)
  local lines = {}
  for _, e in ipairs(entries) do
    lines[#lines + 1] = vim.json.encode(e)
  end
  vim.fn.writefile(lines, session)
end

-- pi format: {type = "message", message = {role, content}}
jsonl({
  { type = "message", message = { role = "user", content = { { type = "text", text = "q" } } } },
  { type = "message", message = { role = "assistant", content = { { type = "text", text = "old answer" } } } },
})
local marker = response.marker(pi_agent)
assert(marker.file == session and marker.offset > 0)

local text = assert(response.final(pi_agent))
assert(text == "old answer", text)

-- nothing after the marker yet
local none, nerr = response.final(pi_agent, marker)
assert(none == nil and nerr:find("no assistant response"), tostring(nerr))

-- claude format after the marker: sidechains and tool-only messages are
-- skipped, the last text message wins, multiple text parts join
local f = io.open(session, "ab")
f:write(vim.json.encode({ type = "assistant", isSidechain = true,
  message = { role = "assistant", content = { { type = "text", text = "subagent noise" } } } }) .. "\n")
f:write(vim.json.encode({ type = "assistant",
  message = { role = "assistant", content = { { type = "tool_use", id = "t1" } } } }) .. "\n")
f:write(vim.json.encode({ type = "assistant",
  message = { role = "assistant", content = { { type = "text", text = "mid" } } } }) .. "\n")
f:write(vim.json.encode({ type = "assistant",
  message = { role = "assistant", content = {
    { type = "text", text = "final" }, { type = "text", text = "answer" } } } }) .. "\n")
f:close()

text = assert(response.final(pi_agent, marker))
assert(text == "final\nanswer", text)
assert(response.final(pi_agent) == "final\nanswer", "unmarked read sees whole file")

-- v2: inject extmark tracking — region follows edits above it and the
-- response replaces the tracked region, not the original line numbers
local inject = require("herdr-agents.inject")
vim.cmd("enew")
local buf = vim.api.nvim_get_current_buf()
vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "keep1", "old1", "old2", "keep2" })

local sent
package.loaded["herdr-agents.api"].request = nil -- ensure real fn below is restored
local real_api = require("herdr-agents.api")
local real_request, real_selected = real_api.request, real_api.selected
real_api.selected = function()
  return "wX:p1"
end
real_api.request = function(_, build, _, cb)
  sent = build({ pane_id = "wX:p1", cwd = "/nowhere" })
  -- user keeps editing above the target while the "agent" works
  vim.api.nvim_buf_set_lines(buf, 0, 0, false, { "inserted above" })
  cb(nil, { status = "idle", text = "```\nnew1\nnew2\nnew3\n```" })
end

inject.start(buf, 2, 3, "replace these")
assert(sent:find("INJECT MODE", 1, true), "inject built the template")
assert(sent:find("old1\nold2", 1, true), "target captured")

local got = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
assert(vim.deep_equal(got, { "inserted above", "keep1", "new1", "new2", "new3", "keep2" }),
  vim.inspect(got))

-- injected highlight is present, then clearable under the cursor
local ns = vim.api.nvim_create_namespace("herdr-agents-injected")
local marks = vim.api.nvim_buf_get_extmarks(buf, ns, 0, -1, {})
assert(#marks == 3, "one sign per injected line, got " .. #marks)
vim.api.nvim_win_set_cursor(0, { 4, 0 })
inject.clear_highlights(buf)
marks = vim.api.nvim_buf_get_extmarks(buf, ns, 0, -1, {})
assert(#marks == 0, "highlight cleared, got " .. #marks)

-- deleting the target region drops the injection instead of misplacing it
vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "keep1", "old1", "old2", "keep2" })
real_api.request = function(_, _, _, cb)
  vim.api.nvim_buf_set_lines(buf, 1, 3, false, {})
  cb(nil, { status = "idle", text = "should not land" })
end
inject.start(buf, 2, 3, "replace these")
got = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
assert(vim.deep_equal(got, { "keep1", "keep2" }), vim.inspect(got))

real_api.request, real_api.selected = real_request, real_selected

print("smoke OK")
