local config = require("tibber.config")
local floating = require("tibber.floating")
local tibber_api = require("tibber.tibber_api")
local convert = require("tibber.convert")

local M = {}


--- Specify your own configuration
---@param user_config Tibber.Config
M.setup = function(user_config)
    config.set_config(user_config)
end


--- Toggle last opened floating window
M.toggle_window = function()
    local curr_data = tibber_api.get_price_data()
    local parsed_data = convert.convert_data(curr_data.homes[1], config.Config)

    floating.toggle_window(parsed_data)
end


return M
