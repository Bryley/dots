local mode_map = {
    n = { "NORMAL", "%#StatusModeNormal#" },
    i = { "INSERT", "%#StatusModeInsert#" },
    v = { "VISUAL", "%#StatusModeVisual#" },
    V = { "V-LINE", "%#StatusModeVisual#" },
    ["\22"] = { "V-BLOCK", "%#StatusModeVisual#" },
    c = { "COMMAND", "%#StatusModeCommand#" },
    R = { "REPLACE", "%#StatusModeReplace#" },
    t = { "TERMINAL", "%#StatusModeTerminal#" },
}
local project_root = vim.fn.getcwd()

local filetype_icons = {
    lua = "",
    go = "",
    rust = "",
    javascript = "",
    typescript = "",
    typescriptreact = "",
    python = "",
    markdown = "",
    json = "",
    nix = "",
}

local function set_statusline_highlights()
    local status_bg = vim.o.background == "dark" and "#1f2330" or "#e6e6e6"
    local meta_bg = vim.o.background == "dark" and "#2c313c" or "#d8dee9"

    vim.api.nvim_set_hl(0, "StatusLine", { bg = status_bg })
    vim.api.nvim_set_hl(0, "StatusLineNC", { bg = status_bg })

    vim.api.nvim_set_hl(0, "StatusMeta", {
        fg = vim.o.background == "dark" and "#cdd6f4" or "#2e3440",
        bg = meta_bg,
    })
    vim.api.nvim_set_hl(0, "StatusMetaSep", { fg = meta_bg, bg = status_bg })

    vim.api.nvim_set_hl(0, "StatusLsp", {
        fg = vim.o.background == "dark" and "#89b4fa" or "#005f87",
        bg = meta_bg,
    })
    vim.api.nvim_set_hl(0, "StatusLspSep", { fg = meta_bg, bg = status_bg })

    vim.api.nvim_set_hl(0, "StatusModeNormal", { fg = "#111111", bg = "#89b4fa", bold = true })
    vim.api.nvim_set_hl(0, "StatusModeInsert", { fg = "#111111", bg = "#a6e3a1", bold = true })
    vim.api.nvim_set_hl(0, "StatusModeVisual", { fg = "#111111", bg = "#cba6f7", bold = true })
    vim.api.nvim_set_hl(0, "StatusModeCommand", { fg = "#111111", bg = "#f9e2af", bold = true })
    vim.api.nvim_set_hl(0, "StatusModeReplace", { fg = "#111111", bg = "#f38ba8", bold = true })
    vim.api.nvim_set_hl(0, "StatusModeTerminal", { fg = "#111111", bg = "#94e2d5", bold = true })

    vim.api.nvim_set_hl(0, "WinbarFileName", { underline = true })
end

local function ensure_statusline_highlights()
    if vim.tbl_isempty(vim.api.nvim_get_hl(0, { name = "StatusModeNormal" })) then
        set_statusline_highlights()
    end
end

local function filename(win)
    local buf = vim.api.nvim_win_get_buf(win)
    local file = vim.api.nvim_buf_get_name(buf)

    if file == "" then
        return ""
    end

    local path
    if file:find(project_root, 1, true) == 1 then
        path = file:sub(#project_root + 2)
    else
        path = vim.fn.fnamemodify(file, ":~")
    end

    local width = vim.api.nvim_win_get_width(win)
    if width < 100 then
        path = vim.fn.pathshorten(path)
    end

    return path
end

local function file_type(win)
    local buf = vim.api.nvim_win_get_buf(win)
    local ft = vim.bo[buf].filetype

    if ft == "" then
        ft = "none"
    end

    local icon = filetype_icons[ft] or ""
    return table.concat({
        "%#StatusMetaSep#",
        "",
        "%#StatusMeta#",
        icon,
        " ",
        ft,
        "%#StatusMetaSep#",
        "",
    })
end

local function lsp_clients(win)
    local buf = vim.api.nvim_win_get_buf(win)
    local clients = vim.lsp.get_clients({ bufnr = buf })

    if #clients == 0 then
        return ""
    end

    local names = {}
    for _, client in ipairs(clients) do
        table.insert(names, client.name)
    end

    return table.concat({
        "%#StatusLspSep#",
        "",
        "%#StatusLsp#",
        " ",
        table.concat(names, ", "),
        "%#StatusLspSep#",
        "",
    })
end

_G.Winbar = function()
    local win = tonumber(vim.g.statusline_winid) or vim.api.nvim_get_current_win()
    return " " .. "%#WinbarFileName#" .. filename(win) .. "%*" .. " "
end

_G.Statusline = function()
    ensure_statusline_highlights()

    local mode = vim.fn.mode()

    local win = tonumber(vim.g.statusline_winid) or vim.api.nvim_get_current_win()

    local opts = mode_map[mode] or { mode, "%#StatusLine#" }
    local mode_name = opts[1]
    local mode_hl = opts[2]

    return table.concat({ mode_hl,
        " ",
        mode_name,
        " ",
        "%#StatusLine#",
        " ",
        filename(win),
        "%=",
        " ",
        file_type(win),
        " ",
        lsp_clients(win),
        "%#StatusLine#",
        " %l:%c %P",
    })
end

set_statusline_highlights()

vim.o.statusline = "%!v:lua.Statusline()"
vim.o.showmode = false
vim.o.laststatus = 3
vim.o.winbar = "%!v:lua.Winbar()"
