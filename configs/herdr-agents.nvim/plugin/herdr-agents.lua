if vim.g.loaded_herdr_agents then
  return
end
vim.g.loaded_herdr_agents = true

require("herdr-agents.commands").register()
