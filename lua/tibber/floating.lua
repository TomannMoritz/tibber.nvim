local Config = {}
local convert = require("tibber.convert")

local M = {}

---@class win_state
---@field buf_nr integer
---@field win_id integer
---@field win_open boolean

---@type win_state
M.state = {
    buf_nr = -1,
    win_id = -1,
    win_open = false,
}


--- Reset the state variables
local function reset_state()
    M.state = {
        buf_nr = -1,
        win_id = -1,
        win_open = false
    }
end


--- Return the config for the floating window
---@param win_title string floating window title
---@return table
local function get_win_config(win_title)
    local status_line_offset = 1
    local nvim_width = vim.api.nvim_win_get_width(0) - status_line_offset
    local nvim_height = vim.api.nvim_win_get_height(0) - status_line_offset

    -- TODO: change width and height
    local win_width = nvim_width;
    local win_height = nvim_height;

    local height_diff = nvim_height - win_height
    local width_diff = nvim_width - win_width
    local first_row = (nvim_height - win_height > 0) and height_diff / 2 or 1
    local first_col = (nvim_width - win_width > 0) and width_diff / 2 or 1

    return {
        row = first_row,
        col = first_col,
        width = win_width,
        height = win_height,
        relative = "win",
        title = win_title,
        border = "single",
        style = "minimal"
    }
end


--- Create a new buffer to store data for the floating window
--- Resets the floating window state (buffer, window id and open status)
M._create_new_floating_buffer = function()
    M.state.buf_nr = vim.api.nvim_create_buf(true, true)
    M.state.win_id = -1
    M.state.win_open = false
end


--- Apply highlight groups
---@param curr_data table
local function apply_highlight_groups(curr_data)
    local ns_tibber = vim.api.nvim_create_namespace("tibber")
    local y_axis_space = 5

    for i, _ in ipairs(curr_data) do
        local price_curr_line = convert.get_price_curr_line(i)
        if price_curr_line < 0 then break end


        if price_curr_line > Config.Pricing.Extreme_Min then
            vim.api.nvim_buf_add_highlight(M.state.buf_nr, ns_tibber, "Tibber_Extreme", i, y_axis_space, -1)
            goto continue
        end


        if price_curr_line > Config.Pricing.High_Min then
            vim.api.nvim_buf_add_highlight(M.state.buf_nr, ns_tibber, "Tibber_High", i, y_axis_space, -1)
            goto continue
        end


        if price_curr_line > Config.Pricing.Mid_Min then
            vim.api.nvim_buf_add_highlight(M.state.buf_nr, ns_tibber, "Tibber_Mid", i, y_axis_space, -1)
            goto continue
        end


        if price_curr_line > Config.Pricing.Low_Min then
            vim.api.nvim_buf_add_highlight(M.state.buf_nr, ns_tibber, "Tibber_Low", i, y_axis_space, -1)
            goto continue
        end

        ::continue::
    end
end


--- Toggle last opened floating window
---@param curr_data table
---@param config table
--- -> Create a new floating window if necessary
M.toggle_window = function(curr_data, config)
    Config = config

    local valid_buffer = vim.api.nvim_buf_is_valid(M.state.buf_nr)
    local valid_open_win = M.state.win_open and M.state.win_id ~= nil

    -- Close window
    if valid_open_win then
        vim.api.nvim_win_close(M.state.win_id, true)

        if valid_buffer then
            vim.api.nvim_buf_delete(M.state.buf_nr, { force = true })
        end

        reset_state()
        return
    end

    -- Create new floating buffer and window
    reset_state()

    M._create_new_floating_buffer()
    vim.api.nvim_buf_set_lines(M.state.buf_nr, 0, 1, false, curr_data)

    apply_highlight_groups(curr_data)

    local win_title = "Pricing"
    M.state.win_id = vim.api.nvim_open_win(M.state.buf_nr, true, get_win_config(win_title))
    M.state.win_open = true
end

return M
