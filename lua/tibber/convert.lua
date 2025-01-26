local M = {}

---@class curr_price_info
---@field min integer
---@field max integer
---@field v_scaling integer
---@field h_scaling integer


---@type curr_price_info
local curr_price_info = {
    min = 0,
    max = 0,
    v_scaling = 0,
    h_scaling = 0
}


--- Calculate the minimum and maximum energy pricing
---@param home_energy_data table
---@return number min_price
---@return number max_price
local function min_max_price(home_energy_data)
    local min_price = 0
    local max_price = 0

    for _, price in ipairs(home_energy_data) do
        local curr_price = tonumber(price.total) or 0

        if (min_price == 0 or curr_price < min_price) then
            min_price = curr_price
        end

        if (max_price == 0 or curr_price > max_price) then
            max_price = curr_price
        end
    end

    return min_price, max_price
end


--- Set information for converting energy prices
---@param home_energy_data table
---@param y_offset number
local function set_price_info(home_energy_data, y_offset)
    local min_price, max_price = min_max_price(home_energy_data)

    curr_price_info.v_scaling = ((vim.api.nvim_win_get_height(0) - y_offset) / max_price) or 50
    curr_price_info.h_scaling = (vim.api.nvim_win_get_width(0) / #home_energy_data) or 50

    min_price = min_price * curr_price_info.v_scaling
    max_price = max_price * curr_price_info.v_scaling

    curr_price_info.min = tonumber(math.floor(min_price)) or 0
    curr_price_info.max = tonumber(math.floor(max_price + 0.5)) or 0

end


--- Convert energy pricing data
---@param home_energy_data table
---@return table
M.convert_data = function(home_energy_data)
    local y_offset = 5
    set_price_info(home_energy_data, y_offset)


    local parsed_pricing = {}
    local y_space = math.floor(y_offset / curr_price_info.v_scaling) + curr_price_info.max

    for i = 0, y_space, 1 do
        local line = ""

        for _, value in ipairs(home_energy_data) do
            local curr_price = tonumber(math.floor(value.total * curr_price_info.v_scaling))

            if i == y_space - curr_price then
                line = line .. string.rep("_", curr_price_info.h_scaling)

            else
                line = line .. string.rep(" ", curr_price_info.h_scaling)
            end
        end

        table.insert(parsed_pricing, line)
    end

    return parsed_pricing
end


return M
