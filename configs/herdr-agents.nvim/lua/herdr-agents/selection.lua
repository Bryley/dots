---Persist the selected Herdr pane per Neovim working directory.

local config = require("herdr-agents.config")

local M = {}

local function path()
  return vim.fs.joinpath(vim.fn.stdpath("state"), "herdr-agents", "selections.json")
end

local function key()
  return vim.fs.normalize(vim.fn.getcwd())
end

local function read_all()
  if vim.fn.filereadable(path()) == 0 then
    return {}
  end

  local lines = vim.fn.readfile(path())
  if #lines == 0 then
    return {}
  end

  local ok, selections = pcall(vim.json.decode, table.concat(lines, "\n"))
  if ok and type(selections) == "table" then
    return selections
  end
  return {}
end

local function write_all(selections)
  vim.fn.mkdir(vim.fn.fnamemodify(path(), ":h"), "p")
  pcall(vim.fn.writefile, { vim.json.encode(selections) }, path())
end

---@return string|nil pane_id
function M.get()
  if not config.options.persist_selection then
    return nil
  end
  return read_all()[key()]
end

---@param pane_id string
function M.set(pane_id)
  if not config.options.persist_selection then
    return
  end
  local selections = read_all()
  selections[key()] = pane_id
  write_all(selections)
end

function M.clear()
  if not config.options.persist_selection then
    return
  end
  local selections = read_all()
  selections[key()] = nil
  write_all(selections)
end

return M
