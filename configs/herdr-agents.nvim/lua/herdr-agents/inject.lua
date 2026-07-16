---Inject mode: bounded AI replacement of a tracked buffer region.
---
---The target region is pinned with an extmark, so edits elsewhere in the
---buffer (above, below, other files) while the agent works do not shift
---where the response lands. Edits inside the target region invalidate the
---injection instead of corrupting it.

local api = require("herdr-agents.api")
local config = require("herdr-agents.config")

local M = {}

local ns_run = vim.api.nvim_create_namespace("herdr-agents-inject-run")
local ns_hl = vim.api.nvim_create_namespace("herdr-agents-injected")

---Highlight blocks of injected code, per buffer: a list of extmark-id
---lists so one :HerdrAgentHighlightClear clears one injection.
---@type table<integer, integer[][]>
local blocks = {}

local function ensure_hl()
  vim.api.nvim_set_hl(0, "HerdrAgentsWorking", { default = true, fg = "#e5924a" })
  vim.api.nvim_set_hl(0, "HerdrAgentsInjected", { default = true, fg = "#e5924a" })
end

ensure_hl()
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("HerdrAgentsInjectHl", { clear = true }),
  callback = ensure_hl,
})

local function err_notify(msg)
  vim.notify("herdr-agents: " .. msg, vim.log.levels.ERROR)
end

---@param bufnr integer
---@param lnum integer 1-based first line
---@param count integer
---@return string
local function get_text(bufnr, lnum, count)
  if count <= 0 then
    return ""
  end
  local lines = vim.api.nvim_buf_get_lines(bufnr, lnum - 1, lnum - 1 + count, false)
  return table.concat(lines, "\n")
end

---Drop a wrapping markdown fence if the agent returned one anyway.
---@param text string
---@return string
local function strip_fences(text)
  local body = text:match("^```[^\n]*\n(.*)\n```%s*$")
  if body then
    return body
  end
  return text
end

---Mark the freshly injected lines in the sign column for review.
---@param bufnr integer
---@param srow integer 0-based first injected row
---@param count integer
local function highlight_block(bufnr, srow, count)
  local hcfg = config.options.inject.highlight
  local ids = {}
  for row = srow, srow + math.max(count, 1) - 1 do
    ids[#ids + 1] = vim.api.nvim_buf_set_extmark(bufnr, ns_hl, row, 0, {
      sign_text = hcfg.sign,
      sign_hl_group = "HerdrAgentsInjected",
      priority = 100,
    })
  end
  blocks[bufnr] = blocks[bufnr] or {}
  table.insert(blocks[bufnr], ids)
  if hcfg.timeout_ms then
    vim.defer_fn(function()
      if vim.api.nvim_buf_is_valid(bufnr) then
        M.clear_block(bufnr, ids)
      end
    end, hcfg.timeout_ms)
  end
end

---@param bufnr integer
---@param ids integer[]
function M.clear_block(bufnr, ids)
  for _, id in ipairs(ids) do
    vim.api.nvim_buf_del_extmark(bufnr, ns_hl, id)
  end
  local bl = blocks[bufnr] or {}
  for i, block in ipairs(bl) do
    if block == ids then
      table.remove(bl, i)
      break
    end
  end
end

---Clear the injected-code highlight under the cursor, or all in `bufnr`.
---@param bufnr integer
---@param all? boolean
function M.clear_highlights(bufnr, all)
  if all then
    vim.api.nvim_buf_clear_namespace(bufnr, ns_hl, 0, -1)
    blocks[bufnr] = nil
    return
  end
  local row = vim.api.nvim_win_get_cursor(0)[1] - 1
  for _, ids in ipairs(blocks[bufnr] or {}) do
    for _, id in ipairs(ids) do
      local pos = vim.api.nvim_buf_get_extmark_by_id(bufnr, ns_hl, id, {})
      if pos[1] == row then
        return M.clear_block(bufnr, ids)
      end
    end
  end
  vim.notify("herdr-agents: no injected-code highlight under cursor", vim.log.levels.INFO)
end

---Apply the agent's response to the tracked region.
---@param bufnr integer
---@param mark integer region extmark id in ns_run
---@param text string
---@return string|nil err
local function apply(bufnr, mark, text)
  local pos = vim.api.nvim_buf_get_extmark_by_id(bufnr, ns_run, mark, { details = true })
  if #pos == 0 or (pos[3] and pos[3].invalid) then
    return "target region was deleted while the agent worked"
  end
  local srow, scol, details = pos[1], pos[2], pos[3]
  local erow, ecol = details.end_row, details.end_col

  if config.options.inject.strip_fences then
    text = strip_fences(text)
  end
  text = text:gsub("\n+$", "")
  local lines = vim.split(text, "\n", { plain = true })

  -- Clamp the tracked end column: the response replaces whole tracked
  -- text, but the buffer may have been reloaded oddly.
  local end_line = vim.api.nvim_buf_get_lines(bufnr, erow, erow + 1, false)[1] or ""
  ecol = math.min(ecol, #end_line)

  vim.api.nvim_buf_set_text(bufnr, srow, scol, erow, ecol, lines)
  highlight_block(bufnr, srow, #lines)
  return nil
end

---Send a bounded replacement request for `line1..line2` of `bufnr` to the
---selected agent and inject the response where the region ends up.
---@param bufnr integer
---@param line1 integer
---@param line2 integer
---@param prompt string
function M.start(bufnr, line1, line2, prompt)
  local sel = api.selected()
  if not sel then
    return err_notify("no agent selected — use :HerdrAgentSelect or :HerdrAgentSpawn first")
  end

  local icfg = config.options.inject
  local total = vim.api.nvim_buf_line_count(bufnr)
  line1 = math.max(1, math.min(line1, total))
  line2 = math.max(line1, math.min(line2, total))

  local file = vim.api.nvim_buf_get_name(bufnr)
  local ctx_first = math.max(1, line1 - icfg.context_lines)
  local ctx = {
    prompt = prompt,
    file = file ~= "" and file or nil,
    line1 = line1,
    line2 = line2,
    target = get_text(bufnr, line1, line2 - line1 + 1),
    before = get_text(bufnr, ctx_first, line1 - ctx_first),
    after = get_text(bufnr, line2 + 1, math.min(total, line2 + icfg.context_lines) - line2),
    filetype = vim.bo[bufnr].filetype or "",
  }

  local last_line = vim.api.nvim_buf_get_lines(bufnr, line2 - 1, line2, false)[1] or ""
  local mark = vim.api.nvim_buf_set_extmark(bufnr, ns_run, line1 - 1, 0, {
    end_row = line2 - 1,
    end_col = #last_line,
    right_gravity = false,
    end_right_gravity = true,
    invalidate = true,
    sign_text = icfg.indicator.sign,
    sign_hl_group = "HerdrAgentsWorking",
    virt_text = { { icfg.indicator.virt_text, "HerdrAgentsWorking" } },
    virt_text_pos = "eol",
  })

  local function finish()
    if vim.api.nvim_buf_is_valid(bufnr) then
      vim.api.nvim_buf_del_extmark(bufnr, ns_run, mark)
    end
  end

  local function build_prompt(agent)
    local path = ctx.file
    if path and agent.cwd and agent.cwd ~= "" then
      local cwd = (agent.cwd:gsub("/+$", ""))
      if vim.startswith(path, cwd .. "/") then
        path = path:sub(#cwd + 2)
      end
    end
    return icfg.prompt(vim.tbl_extend("force", ctx, { file = path }))
  end

  api.request(sel, build_prompt, {
    timeout_ms = icfg.timeout_ms,
    on_blocked = function()
      vim.notify(
        ("herdr-agents: agent %s needs input — answer it in its pane; inject is still pending"):format(sel),
        vim.log.levels.WARN)
    end,
  }, function(err, result)
    if not vim.api.nvim_buf_is_valid(bufnr) then
      return err_notify("inject dropped: buffer was closed while the agent worked")
    end
    if err then
      finish()
      return err_notify("inject failed: " .. err)
    end
    if not result.text or result.text == "" then
      finish()
      return err_notify("inject failed: agent returned no response text")
    end
    local aerr = apply(bufnr, mark, result.text)
    finish()
    if aerr then
      return err_notify("inject dropped: " .. aerr)
    end
    vim.notify(("herdr-agents: injected response from %s (clear mark with :HerdrAgentHighlightClear)"):format(sel),
      vim.log.levels.INFO)
  end)

  vim.notify(("herdr-agents: inject sent to %s"):format(sel), vim.log.levels.INFO)
end

return M
