local config = require("tibber.config")
local floating = require("tibber.floating")
local tibber_api = require("tibber.tibber_api")
local convert = require("tibber.convert")

local M = {}


--- Set highlight groups
local function set_highlight_groups()
    for k, v in pairs(config.Config.Pricing_Groups) do
        vim.api.nvim_set_hl(0, k, v)
    end
end


--- Specify your own configuration
---@param user_config Tibber.Config
M.setup = function(user_config)
    config.set_config(user_config)
end


--- Toggle last opened floating window
M.toggle_window = function()
    local curr_data = tibber_api.get_price_data()
    local parsed_data = convert.convert_data(curr_data.homes[1], config.Config)

    set_highlight_groups()
    floating.toggle_window(parsed_data, config.Config)
end


return M
