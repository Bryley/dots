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

print("smoke OK")
