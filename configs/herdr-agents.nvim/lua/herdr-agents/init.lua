---herdr-agents.nvim — dispatch prompts from Neovim to Herdr-managed agents.

local M = {}

M.config = require("herdr-agents.config").options

---Configure herdr-agents.nvim. Optional: commands work with defaults.
---@param opts? HerdrAgentsConfig|table
function M.setup(opts)
  local config = require("herdr-agents.config")
  config.setup(opts)
  M.config = config.options
  require("herdr-agents.commands").register()
  require("herdr-agents.api").restore_selection()
end

-- Re-export the agent API (list_agents, spawn, select, selected, send,
-- read, fetch_response, watch, close) lazily.
setmetatable(M, {
  __index = function(_, key)
    return require("herdr-agents.api")[key]
  end,
})

return M
