local config = require("tibber.config")
local floating = require("tibber.floating")
local tibber_api = require("tibber.tibber_api")
local convert = require("tibber.convert")
local json = require("tibber.json")

local M = {}
local energy_data = {}


--- Set highlight groups
local function set_highlight_groups()
    for k, v in pairs(config.Config.Pricing_Groups) do
        vim.api.nvim_set_hl(0, k, v)
    end
end


--- Set buffer and display the floating window
local function toggle_display()
    local win_width, win_height = floating.get_win_size(config.Config.Win_Width_Percentage, config.Config.Win_Height_Percentage)
    local parsed_data = convert.convert_data(energy_data.data, config.Config, win_width, win_height)

    set_highlight_groups()
    floating.toggle_window(parsed_data, config.Config, energy_data.title)
end


--- Specify your own configuration
---@param user_config Tibber.Config
M.setup = function(user_config)
    config.set_config(user_config)
end


--- Toggle last opened floating window
---@param requery boolean
M.toggle_window = function(requery)
    local closed_window = not floating.state.win_open
    local is_empty = next(energy_data) == nil

    if (closed_window and requery) or is_empty then
        local price_result = tibber_api.get_price_data()

        -- invalid env: no data/results
        if price_result == nil then return end

        energy_data = price_result.homes[1]
    end

    toggle_display()
end


--- Toggle loaded data
---@param file_path string
M.toggle_load_data = function(file_path)
    local closed_window = not floating.state.win_open
    if not closed_window then
        toggle_display()
        return
    end

    -- open file
    local file = io.open(file_path)
    if file == nil then
        print("[Tibber.nvim] [!] Could not find file: " .. file_path)
        return
    end

    -- read data
    io.input(file)
    local data = io.read("*a")

    if data == nil then
        print("[Tibber.nvim] [!] Could not read data from file: " .. file_path)
        return
    end

    local parsed_data = json.parse(data)
    if parsed_data == nil then
        print("[Tibber.nvim] [!] Could not parse json data: \n" .. data)
        return
    end

    -- Check for valid input data
    local valid_data, error_msg = tibber_api.get_valid_data(parsed_data)
    if valid_data == nil then
        print(error_msg)
        return
    end

    energy_data = valid_data
    toggle_display()
end


-- Resize and rescale with resize autocommand
vim.api.nvim_create_autocmd("VimResized", {
    group = vim.api.nvim_create_augroup("tibber-resize", {}),
    callback = function()
        toggle_display()
        toggle_display()
    end
})

return M
