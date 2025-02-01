local M = {}

local SPACE = " "
local EMPTY = ""
local BAR_CHAR_TOP = "_"
local BAR_CHAR_SIDE = "|"
local BAR_CHAR_INSIDE = "."

local SECONDS_A_MINUTE = 60
local MINUTES_A_HOUR = 60
local HOURS_A_DAY = 24
local SECONDS_A_DAY = SECONDS_A_MINUTE * MINUTES_A_HOUR * HOURS_A_DAY

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


--- Return number string with leading zeros
---@param value any
---@param positions number
---@return string
local function pad_number(value, positions)
    local number_str = tostring(value)
    positions = positions or 2
    return string.rep("0", positions - #number_str) .. number_str
end

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

    curr_price_info.v_scaling = math.floor(curr_price_info.v_scaling)
    curr_price_info.h_scaling = math.floor(curr_price_info.h_scaling)

    min_price = min_price * curr_price_info.v_scaling
    max_price = max_price * curr_price_info.v_scaling

    curr_price_info.min = tonumber(math.floor(min_price)) or 0
    curr_price_info.max = tonumber(math.floor(max_price + 0.5)) or 0

end


--- Get bar character if necessary
---@param home_energy_data table
---@param price_curr_line integer
---@param hour_index integer
---@param price_curr_hour integer
---@return string char (bar character)
local function left_bar_up(home_energy_data, price_curr_line, hour_index, price_curr_hour)
    if hour_index - 1 == 0 then return EMPTY end

    local prev_price = tonumber(math.floor(home_energy_data[hour_index - 1].total * curr_price_info.v_scaling))
    if prev_price > price_curr_hour then return EMPTY end


    if price_curr_line >= prev_price and price_curr_line < price_curr_hour then
        return BAR_CHAR_SIDE
    end

    return EMPTY
end


--- Get bar character if necessary
---@param home_energy_data table
---@param price_curr_line integer
---@param hour_index integer
---@param price_curr_hour integer
---@return string char (bar character)
local function right_bar_down(home_energy_data, price_curr_line, hour_index, price_curr_hour)
    if hour_index == #home_energy_data then return EMPTY end

    local price_next_hour = tonumber(math.floor(home_energy_data[hour_index + 1].total * curr_price_info.v_scaling))
    if price_next_hour > price_curr_hour then return EMPTY end


    if price_curr_line < price_curr_hour and price_curr_line >= price_next_hour then
        return BAR_CHAR_SIDE
    end

    return EMPTY
end


--- Get hours string for energy prices
---@param home_energy_data table
---@return string
local function get_info_hours(home_energy_data)
    local info_hours = ""

    for i = 0, #home_energy_data - 1 do
        if curr_price_info.h_scaling < 5 and i % 2 == 1 then
            info_hours = info_hours .. string.rep(SPACE, curr_price_info.h_scaling)
            goto continue
        end

        local curr_hour = tostring(i % 24)

        local spacing = (curr_price_info.h_scaling - #curr_hour) / 2
        local space_remainder = (curr_price_info.h_scaling - #curr_hour) % 2


        info_hours = info_hours .. string.rep(SPACE, spacing) .. curr_hour .. string.rep(SPACE, spacing + space_remainder)
        ::continue::
    end

    return info_hours
end


--- Get days string for energy prices
--- ISO 8601: YYYY-MM-DD
---@param home_energy_data table
---@return string
local function get_info_days(home_energy_data)
    local curr_time = os.time()

    local number_days = #home_energy_data / HOURS_A_DAY
    local space_line = curr_price_info.h_scaling * HOURS_A_DAY
    local info_days = EMPTY

    for i = 0, number_days - 1 do
        local day_time = os.date("*t", curr_time + i * SECONDS_A_DAY)
        local day_str = tostring(day_time.year) .. "-" .. pad_number(day_time.month, 2) .. "-" .. pad_number(day_time.day, 2)

        local spacing = (space_line - #day_str - 2) / 2

        day_str = BAR_CHAR_SIDE .. string.rep(SPACE, spacing) .. day_str .. string.rep(SPACE, spacing) .. BAR_CHAR_SIDE
        info_days = info_days .. day_str
    end

    return info_days
end


--- Add x-axis information (hours and days)
---@param parsed_pricing table
---@param home_energy_data table
local function bottom_info(parsed_pricing, home_energy_data)
    local x_axis = string.rep(BAR_CHAR_TOP, curr_price_info.h_scaling * #home_energy_data)
    table.insert(parsed_pricing, x_axis)


    local info_hours = get_info_hours(home_energy_data)
    table.insert(parsed_pricing, info_hours)


    local info_days = get_info_days(home_energy_data)
    table.insert(parsed_pricing, info_days)
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
        local price_curr_line = y_space - i

        for hour_index, price_curr_hour in ipairs(home_energy_data) do
            price_curr_hour = tonumber(math.floor(price_curr_hour.total * curr_price_info.v_scaling)) or -1

            if price_curr_line == price_curr_hour then
                line = line .. string.rep(BAR_CHAR_TOP, curr_price_info.h_scaling)
                goto continue
            end


            -- Add left side
            local char_space_left = curr_price_info.h_scaling
            local add_line = left_bar_up(home_energy_data, price_curr_line, hour_index, price_curr_hour)
            line = line .. add_line
            char_space_left = char_space_left - #add_line



            -- Add mid section
            local mid_section = SPACE
            if hour_index % 2 == 0 and price_curr_line < price_curr_hour then
                mid_section = BAR_CHAR_INSIDE
            end
            if char_space_left > 1 then
                line = line .. string.rep(mid_section, char_space_left - 1)
                char_space_left = 1
            end


            -- Add right side
            add_line = right_bar_down(home_energy_data, price_curr_line, hour_index, price_curr_hour)
            line = line .. add_line
            char_space_left = char_space_left - #add_line


            -- Add remaining spaces
            if char_space_left > 0 then
                line = line .. string.rep(mid_section, char_space_left)
            end


            ::continue::
        end

        table.insert(parsed_pricing, line)
    end


    -- Add x-axis information
    bottom_info(parsed_pricing, home_energy_data)

    return parsed_pricing
end


return M
