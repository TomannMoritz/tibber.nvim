local config = require("tibber.config")
local floating = require("tibber.floating")
local tibber_api = require("tibber.tibber_api")
local convert = require("tibber.convert")

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
    local parsed_data = convert.convert_data(energy_data.homes[1], config.Config, win_width, win_height)

    set_highlight_groups()
    floating.toggle_window(parsed_data, config.Config)
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
        energy_data = tibber_api.get_price_data()
    end

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
