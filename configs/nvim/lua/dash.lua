-- Tiny startup dashboard, intentionally no plugin.
-- Shows only on `nvim` with no file args, then clears as soon as editing starts.

vim.opt.shortmess:append("I") -- hide built-in intro

local ns = vim.api.nvim_create_namespace("bryley_dash")

-- TODO add nvim version, plugin count and CWD to the dash
local cwd = vim.fn.fnamemodify(vim.fn.getcwd(), ":~")
local version = vim.version()
local nvim_version = ("v%d.%d.%d"):format(version.major, version.minor, version.patch)


local art = {
    {[[                                                                     ]], "Function"},
    {[[       ████ ██████           █████      ██                     ]], "Function"},
    {[[      ███████████             █████                             ]], "Function"},
    {[[      █████████ ███████████████████ ███   ███████████   ]], "Function"},
    {[[     █████████  ███    █████████████ █████ ██████████████   ]], "Function"},
    {[[    █████████ ██████████ █████████ █████ █████ ████ █████   ]], "Function"},
    {[[  ███████████ ███    ███ █████████ █████ █████ ████ █████   ]], "Function"},
    {[[ ██████  █████████████████████ ████ █████ █████ ████ ██████ ]], "Function"},
    -- { " " .. nvim_version, "Comment"},
    -- { " " .. cwd, "Comment"},
}

local function is_empty_startup_buffer(buf)
    return vim.fn.argc() == 0
        and vim.bo[buf].buftype == ""
        and not vim.bo[buf].modified
        and vim.api.nvim_buf_line_count(buf) == 1
        and vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] == ""
end

local function centered(line, width)
    local pad = math.max(0, math.floor((width - vim.fn.strdisplaywidth(line)) / 2))
    return string.rep(" ", pad) .. line
end

local function clear(buf)
    buf = buf or vim.api.nvim_get_current_buf()
    if vim.api.nvim_buf_is_valid(buf) then
        vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
        vim.b[buf].dash_active = false
    end
end

local function draw()
    local buf = vim.api.nvim_get_current_buf()
    if not is_empty_startup_buffer(buf) then
        return
    end

    clear(buf)

    local width = vim.api.nvim_win_get_width(0)
    local height = vim.api.nvim_win_get_height(0)
    local top_padding = math.max(0, math.floor((height - #art) / 2) - 1)
    local virt_lines = {}

    for _ = 1, top_padding do
        table.insert(virt_lines, { { "", "Comment" } })
    end

    for _, line in ipairs(art) do
        table.insert(virt_lines, { { centered(line[1], width), line[2]} })
    end

    vim.api.nvim_buf_set_extmark(buf, ns, 0, 0, {
        virt_lines = virt_lines,
        -- Put the virtual lines below the empty buffer line. Lines placed
        -- "above" line 0 can sit outside the visible viewport on startup.
        virt_lines_above = false,
        priority = 10,
    })

    vim.b[buf].dash_active = true
end

vim.api.nvim_create_autocmd("VimEnter", {
    callback = function()
        vim.schedule(draw)
    end,
})

vim.api.nvim_create_autocmd({ "InsertEnter", "TextChanged", "TextChangedI", "BufReadPre", "BufNewFile" }, {
    callback = function(args)
        clear(args.buf)
    end,
})

vim.api.nvim_create_autocmd("VimResized", {
    callback = function()
        local buf = vim.api.nvim_get_current_buf()
        if vim.b[buf].dash_active then
            vim.schedule(draw)
        end
    end,
})
