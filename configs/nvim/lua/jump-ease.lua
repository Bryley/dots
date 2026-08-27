local M = {}

local digit_cost = {
    ["1"] = 1,
    ["2"] = 0,
    ["3"] = 0,
    ["4"] = 0,
    ["5"] = 1,
    ["6"] = 2,
    ["7"] = 3,
    ["8"] = 3,
    ["9"] = 2,
    ["0"] = 3,
}

-- Right index: 6, 7, j. Right middle: 8, k.
local motion_finger = { j = "index", k = "middle" }
local digit_finger = { ["6"] = "index", ["7"] = "index", ["8"] = "middle" }

local function group_for(relative, motion)
    local number = tostring(relative)
    local cost = 0

    for digit in number:gmatch("%d") do
        cost = cost + digit_cost[digit]
    end
    cost = cost / #number

    -- Repeated home-side digits are particularly comfortable (22, 33, 44).
    if #number > 1 and number:match("^(%d)%1+$") and digit_cost[number:sub(1, 1)] <= 1 then
        cost = cost - 1
    end

    local last_finger = digit_finger[number:sub(-1)]
    if last_finger and last_finger == motion_finger[motion] then
        cost = cost + 1
    end

    if cost <= 0 then
        return "JumpEaseHigh"
    elseif cost <= 1 then
        return "JumpEaseMedium"
    elseif cost <= 2 then
        return "JumpEaseLow"
    end
    return "JumpEaseHard"
end

function M.statuscolumn()
    -- Virtual dashboard lines all refer to buffer line 1; don't render a
    -- misleading column of repeated "1" values beside them.
    if vim.v.virtnum ~= 0 then
        return ""
    end

    local win = tonumber(vim.g.statusline_winid) or vim.api.nvim_get_current_win()
    local buf = vim.api.nvim_win_get_buf(win)
    local width = math.max(vim.wo[win].numberwidth, #tostring(vim.api.nvim_buf_line_count(buf)))
    local number

    if vim.v.relnum == 0 then
        number = string.format("%%#CursorLineNr#%d%%* ", vim.v.lnum)
        return "%C%s" .. number
    end

    local cursor_line = vim.api.nvim_win_get_cursor(win)[1]
    local motion = vim.v.lnum > cursor_line and "j" or "k"
    number = string.format("%%#%s#%" .. width .. "d%%* ", group_for(vim.v.relnum, motion), vim.v.relnum)
    return "%C%s%=" .. number
end

local function blend(foreground, background, amount)
    local channels = {}
    for index = 1, 3 do
        local shift = (3 - index) * 8
        local fg = (foreground >> shift) & 0xff
        local bg = (background >> shift) & 0xff
        channels[index] = math.floor(fg + (bg - fg) * amount + 0.5)
    end
    return string.format("#%02x%02x%02x", channels[1], channels[2], channels[3])
end

local function set_highlights()
    local line_number = vim.api.nvim_get_hl(0, { name = "LineNr", link = false }).fg
    local background = vim.api.nvim_get_hl(0, { name = "Normal", link = false }).bg

    if not line_number or not background then
        return
    end

    -- Keep the theme's native line-number color; progressively fade hard jumps.
    vim.api.nvim_set_hl(0, "JumpEaseHigh", { link = "LineNr" })
    vim.api.nvim_set_hl(0, "JumpEaseMedium", { fg = blend(line_number, background, 0.25) })
    vim.api.nvim_set_hl(0, "JumpEaseLow", { fg = blend(line_number, background, 0.5) })
    vim.api.nvim_set_hl(0, "JumpEaseHard", { fg = blend(line_number, background, 0.72) })
end

function M.setup()
    set_highlights()
    vim.opt.statuscolumn = "%!v:lua.require'jump-ease'.statuscolumn()"

    vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("jump_ease_highlights", { clear = true }),
        callback = set_highlights,
    })
end

return M
