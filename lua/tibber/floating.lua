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
local function create_new_floating_buffer()
    M.state.buf_nr = vim.api.nvim_create_buf(true, true)
    M.state.win_id = -1
    M.state.win_open = false
end


--- Toggle last opened floating window
---@param curr_data table
--- -> Create a new floating window if necessary
M.toggle_window = function(curr_data)
    local valid_buffer = vim.api.nvim_buf_is_valid(M.state.buf_nr)
    if not valid_buffer then
        create_new_floating_buffer()

        -- Add data to buffer
        vim.api.nvim_buf_set_lines(M.state.buf_nr, 0, 1, false, curr_data)
    end


    local valid_open_win = M.state.win_open and M.state.win_id ~= nil
    if valid_open_win then
        vim.api.nvim_win_close(M.state.win_id, true)
        M.state.win_open = false
        return
    end



    local win_title = "Pricing"
    M.state.win_id = vim.api.nvim_open_win(M.state.buf_nr, true, get_win_config(win_title))
    M.state.win_open = true
end

return M
