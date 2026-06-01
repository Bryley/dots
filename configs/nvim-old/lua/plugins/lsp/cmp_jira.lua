local M = {}
M._registered = false

local cache = {
    records = {},
    fetched_at = 0,
    in_flight = false,
}

local config = {
    cache_ttl_ms = 300000,
    prewarm = false,
    in_progress_statuses = { "In Progress" },
    done_statuses = { "Done", "Closed" },
    done_recent_days = 3,
    priority_keywords = { "P1", "P2", "High" },
    max_results = 200,
    debug = false,
}

local function now_ms()
    return vim.loop.now()
end

local function is_cache_fresh()
    return cache.fetched_at > 0 and (now_ms() - cache.fetched_at) < config.cache_ttl_ms
end

local function to_set(list)
    local set = {}
    for _, item in ipairs(list or {}) do
        set[string.lower(item)] = true
    end
    return set
end

local function priority_matches(priority, keywords)
    if not priority or priority == "" then
        return false
    end
    local lower = string.lower(priority)
    for _, keyword in ipairs(keywords or {}) do
        if string.find(lower, string.lower(keyword), 1, true) then
            return true
        end
    end
    return false
end

local function parse_time(value)
    if not value or value == "" then
        return 0
    end
    local trimmed = string.sub(value, 1, 19)
    local ok, ts = pcall(vim.fn.strptime, "%Y-%m-%dT%H:%M:%S", trimmed)
    if not ok or not ts then
        return 0
    end
    return ts
end

local function inline_text(node, acc)
    if type(node) ~= "table" then
        return
    end
    if node.type == "text" and node.text then
        table.insert(acc, node.text)
        return
    end
    for _, child in ipairs(node.content or {}) do
        inline_text(child, acc)
    end
end

local function doc_to_lines(node, lines)
    if type(node) ~= "table" then
        return
    end

    if node.type == "paragraph" then
        local acc = {}
        inline_text(node, acc)
        local line = table.concat(acc)
        if line ~= "" then
            table.insert(lines, line)
        end
        return
    end

    if node.type == "listItem" then
        local first = true
        for _, child in ipairs(node.content or {}) do
            if child.type == "paragraph" then
                local acc = {}
                inline_text(child, acc)
                local line = table.concat(acc)
                if line ~= "" then
                    if first then
                        table.insert(lines, "- " .. line)
                        first = false
                    else
                        table.insert(lines, "  " .. line)
                    end
                end
            else
                doc_to_lines(child, lines)
            end
        end
        return
    end

    if node.type == "bulletList" then
        for _, child in ipairs(node.content or {}) do
            doc_to_lines(child, lines)
        end
        return
    end

    if node.type == "orderedList" then
        local idx = 1
        for _, child in ipairs(node.content or {}) do
            if child.type == "listItem" then
                local first = true
                for _, item in ipairs(child.content or {}) do
                    if item.type == "paragraph" then
                        local acc = {}
                        inline_text(item, acc)
                        local line = table.concat(acc)
                        if line ~= "" then
                            if first then
                                table.insert(lines, tostring(idx) .. ". " .. line)
                                first = false
                            else
                                table.insert(lines, "  " .. line)
                            end
                        end
                    else
                        doc_to_lines(item, lines)
                    end
                end
                idx = idx + 1
            else
                doc_to_lines(child, lines)
            end
        end
        return
    end

    for _, child in ipairs(node.content or {}) do
        doc_to_lines(child, lines)
    end
end

function M.description_to_text(doc)
    local lines = {}
    doc_to_lines(doc, lines)
    return table.concat(lines, "\n")
end

local function score_record(record)
    local in_progress = to_set(config.in_progress_statuses)
    local done = to_set(config.done_statuses)
    local now = os.time()
    local done_recent_after = now - (config.done_recent_days * 86400)

    local status = string.lower(record.status or "")
    local is_in_progress = in_progress[status]
    local is_done = done[status]
    local is_done_recent = is_done and record.updated_ts >= done_recent_after
    local is_prioritized = priority_matches(record.priority, config.priority_keywords)
    local is_open = (not is_done) and (not is_in_progress)

    if is_in_progress then
        return 1
    end
    if is_done_recent then
        return 2
    end
    if is_prioritized then
        return 3
    end
    if is_open then
        return 4
    end
    return 5
end

local function sort_records(records)
    for _, record in ipairs(records) do
        record.score = score_record(record)
    end
    table.sort(records, function(a, b)
        if a.score == b.score then
            return a.updated_ts > b.updated_ts
        end
        return a.score < b.score
    end)
end

local function build_command()
    local cmd = { "jira", "issue", "list", "--raw" }
    local assignee = M.assignee
    if not assignee then
        local ok, out = pcall(vim.fn.systemlist, { "jira", "me" })
        if ok and out and out[1] and out[1] ~= "" then
            assignee = out[1]
            M.assignee = assignee
        end
    end
    if assignee and assignee ~= "" then
        table.insert(cmd, "-a")
        table.insert(cmd, assignee)
    end
    if config.jql and config.jql ~= "" then
        table.insert(cmd, "-q")
        table.insert(cmd, config.jql)
    end
    if config.max_results and config.max_results > 0 then
        table.insert(cmd, "--paginate")
        table.insert(cmd, "0:" .. tostring(config.max_results))
    end
    return cmd
end

local function extract_records(decoded)
    local records = {}
    for _, issue in ipairs(decoded or {}) do
        local key = issue.key or ""
        local fields = issue.fields or {}
        local summary = fields.summary or ""
        local description = ""
        local status = fields.status and fields.status.name or ""
        local labels = fields.labels or {}
        local priority = fields.priority and fields.priority.name or ""
        local assignee = fields.assignee and fields.assignee.displayName or ""
        local updated = fields.updated or ""
        local updated_ts = parse_time(updated)

        if fields.description and type(fields.description) == "table" then
            description = M.description_to_text(fields.description)
        end

        if key ~= "" then
            table.insert(records, {
                key = key,
                summary = summary,
                description = description,
                status = status,
                labels = labels,
                priority = priority,
                assignee = assignee,
                updated = updated,
                updated_ts = updated_ts,
            })
        end
    end
    sort_records(records)
    return records
end

local function refresh_cache(trigger_complete)
    if cache.in_flight then
        return
    end

    cache.in_flight = true
    local output = {}

    vim.fn.jobstart(build_command(), {
        stdout_buffered = true,
        on_stdout = function(_, data)
            if not data then
                return
            end
            for _, line in ipairs(data) do
                if line ~= "" then
                    table.insert(output, line)
                end
            end
        end,
        on_exit = function()
            cache.in_flight = false
            local text = table.concat(output, "")
            local ok, decoded = pcall(vim.json.decode, text)
            if not ok or type(decoded) ~= "table" then
                return
            end
            cache.records = extract_records(decoded)
            cache.fetched_at = now_ms()

            if trigger_complete then
                vim.schedule(function()
                    local ok_cmp, cmp = pcall(require, "cmp")
                    if not ok_cmp then
                        return
                    end
                    if vim.fn.mode() ~= "i" then
                        return
                    end
                    cmp.complete()
                end)
            end
        end,
    })
end

local function get_prefix(params)
    local line = params.context and params.context.cursor_before_line or nil
    if not line then
        local current = vim.api.nvim_get_current_line()
        local col = vim.api.nvim_win_get_cursor(0)[2] + 1
        line = string.sub(current, 1, col)
    end
    if not line then
        return nil
    end
    return string.match(line, "(PK%-%w*)$")
end

local function filtered_items(prefix)
    local items = {}
    local prefix_upper = string.upper(prefix)
    for _, record in ipairs(cache.records) do
        local key_upper = string.upper(record.key)
        if prefix_upper == "PK-" or string.sub(key_upper, 1, #prefix_upper) == prefix_upper then
            local metadata = {}
            if record.status and record.status ~= "" then
                table.insert(metadata, "- Status: " .. record.status)
            end
            if record.priority and record.priority ~= "" then
                table.insert(metadata, "- Priority: " .. record.priority)
            end
            if record.assignee and record.assignee ~= "" then
                table.insert(metadata, "- Assignee: " .. record.assignee)
            end
            if record.updated and record.updated ~= "" then
                table.insert(metadata, "- Updated: " .. record.updated)
            end
            local doc = {
                "### " .. record.key .. " " .. record.summary,
            }
            if #metadata > 0 then
                for _, line in ipairs(metadata) do
                    table.insert(doc, line)
                end
            end
            if record.description and record.description ~= "" then
                table.insert(doc, "")
                table.insert(doc, record.description)
            end

            table.insert(items, {
                label = record.key,
                detail = record.summary,
                documentation = {
                    kind = "markdown",
                    value = table.concat(doc, "\n"),
                },
            })
        end
    end
    return items
end

function M.setup(opts)
    config = vim.tbl_deep_extend("force", config, opts or {})

    if not M._registered then
        local ok_cmp, cmp = pcall(require, "cmp")
        if ok_cmp then
            cmp.register_source("jira", M.new())
            M._registered = true
            if config.debug then
                vim.notify("cmp_jira registered source")
            end
        end
    end

    if config.prewarm then
        vim.api.nvim_create_autocmd("VimEnter", {
            callback = function()
                refresh_cache(false)
            end,
        })
    end

    vim.api.nvim_create_autocmd({ "TextChangedI", "TextChangedP" }, {
        callback = function()
            local line = vim.api.nvim_get_current_line()
            local col = vim.api.nvim_win_get_cursor(0)[2] + 1
            local before = string.sub(line, 1, col)
            if not string.match(before, "PK%-%w*$") then
                return
            end
            local ok_cmp, cmp = pcall(require, "cmp")
            if not ok_cmp then
                return
            end
            if cmp.visible() then
                return
            end
            cmp.complete({
                config = {
                    sources = {
                        { name = "jira" },
                    },
                },
            })
        end,
    })
end

function M.new()
    return setmetatable({}, { __index = M })
end

function M:is_available()
    local line = vim.api.nvim_get_current_line()
    local col = vim.api.nvim_win_get_cursor(0)[2] + 1
    local before = string.sub(line, 1, col)
    if config.debug then
        vim.notify("cmp_jira is_available before=" .. before)
    end
    return string.match(before, "PK%-%w*$") ~= nil
end

function M:get_keyword_pattern()
    return [[\%(\k\|-\)\+]]
end

function M:get_trigger_characters()
    return { "-" }
end

function M:complete(params, callback)
    local prefix = get_prefix(params)
    if config.debug then
        vim.schedule(function()
            vim.notify("cmp_jira complete prefix=" .. tostring(prefix))
        end)
    end
    if not prefix then
        callback({ items = {} })
        return
    end

    if not is_cache_fresh() then
        refresh_cache(true)
    end

    local items = filtered_items(prefix)
    callback({
        items = items,
        isIncomplete = not is_cache_fresh(),
    })
end

return M
