local Config = {}
local win_width = 0
local win_height = 0


local M = {}

local SPACE = " "
local DASH = "-"
local EMPTY = ""

local SECONDS_A_MINUTE = 60
local MINUTES_A_HOUR = 60
local HOURS_A_DAY = 24
local SECONDS_A_DAY = SECONDS_A_MINUTE * MINUTES_A_HOUR * HOURS_A_DAY

local CENTS_A_EURO = 100

---@class curr_price_info
---@field max_price integer
---@field y_space integer
---@field v_scaling integer
---@field h_scaling integer


---@type curr_price_info
local curr_price_info = {
    max_price = 0,
    y_space = 0,
    v_scaling = 0,
    h_scaling = 0
}


--- Return data as string with leading padding on the left
---@param value any
---@param pad_value any
---@param positions number
---@return string
local function pad_left(value, pad_value, positions)
    local number_str = tostring(value)

    pad_value = pad_value or 0
    positions = positions or 2
    return string.rep(tostring(pad_value), positions - #number_str) .. number_str
end


--- Calculate the minimum and maximum energy pricing
---@param home_energy_data table
---@return number max_price
local function get_max_price(home_energy_data)
    local max_price = 0

    for _, price in ipairs(home_energy_data) do
        local curr_price = tonumber(price.value) or 0

        if (max_price == 0 or curr_price > max_price) then
            max_price = curr_price
        end
    end

    return max_price
end


--- Set information for converting energy prices
---@param home_energy_data homes_data
local function set_price_info(home_energy_data)
    local max_price = get_max_price(home_energy_data)
    local add_line_info = 5
    if (win_height - Config.Height_Offset <= 0) then add_line_info = 0 end

    -- update min bar width
    for _, data in ipairs(home_energy_data) do
        local key = data.key

        if key ~= nil then
            -- keep space before and after the key label
            Config.Min_Bar_Width = math.max(Config.Min_Bar_Width, #key + #SPACE * 2)
        end
    end

    max_price = math.max(max_price, Config.Min_Bar_Height / CENTS_A_EURO)

    curr_price_info.v_scaling = math.floor((win_height - Config.Height_Offset - add_line_info) / max_price)
    curr_price_info.h_scaling = math.floor(win_width / #home_energy_data)

    curr_price_info.h_scaling = math.max(curr_price_info.h_scaling, Config.Min_Bar_Width)

    curr_price_info.y_space = Config.Height_Offset + math.floor(max_price * curr_price_info.v_scaling)
    curr_price_info.max_price = math.floor(max_price * CENTS_A_EURO + 0.5)
end


--- Get bar character if necessary
---@param home_energy_data table
---@param price_curr_line integer
---@param hour_index integer
---@param mid_section string
---@param price_curr_hour integer
---@return string char (bar character)
local function left_bar_up(home_energy_data, price_curr_line, hour_index, price_curr_hour, mid_section)
    if hour_index - 1 == 0 then return mid_section end

    local prev_price = tonumber(math.floor(home_energy_data[hour_index - 1].value * curr_price_info.v_scaling))
    if prev_price > price_curr_hour then return mid_section end


    if price_curr_line >= prev_price and price_curr_line < price_curr_hour then
        return Config.Char_Bar_Side
    end

    return mid_section
end


--- Get bar character if necessary
---@param home_energy_data table
---@param price_curr_line integer
---@param hour_index integer
---@param price_curr_hour integer
---@param mid_section string
---@return string char (bar character)
local function right_bar_down(home_energy_data, price_curr_line, hour_index, price_curr_hour, mid_section)
    if hour_index == #home_energy_data then return mid_section end

    local price_next_hour = tonumber(math.floor(home_energy_data[hour_index + 1].value * curr_price_info.v_scaling))
    if price_next_hour > price_curr_hour then return mid_section end


    if price_curr_line < price_curr_hour and price_curr_line >= price_next_hour then
        return Config.Char_Bar_Side
    end

    return mid_section
end


--- Get key string from energy data
---@param home_energy_data homes_data
---@return string
local function get_info_keys(home_energy_data)
    local info_keys = ""

    for _, data in ipairs(home_energy_data) do
        local curr_hour = data.key
        local spacing = (curr_price_info.h_scaling - #curr_hour) / 2
        local space_remainder = (curr_price_info.h_scaling - #curr_hour) % 2

        curr_hour = string.rep(SPACE, spacing + space_remainder) .. curr_hour .. string.rep(SPACE, spacing)
        info_keys = info_keys .. curr_hour
    end

    return info_keys
end


--- Get label string from energy data
---@param home_energy_data homes_data
---@return string
local function get_info_labels(home_energy_data)
    local info_label = EMPTY
    local curr_label = EMPTY
    local prev_pos = 1

    for pos, data in ipairs(home_energy_data) do
        local label = data.label

        if curr_label == EMPTY then
            curr_label = label
        end

        local last_ele = #home_energy_data - 1 == pos
        if last_ele then
            local start_offset = 1
            local end_offset = 1
            pos = pos +  start_offset + end_offset
        end

        -- insert label centered
        if curr_label ~= label or last_ele then
            local label_space = (pos - prev_pos) * curr_price_info.h_scaling
            label_space = label_space - 2

            -- cut long labels
            curr_label = string.sub(curr_label, 1, label_space)
            label_space = label_space - #curr_label

            local spacing = label_space / 2
            local space_remaining = label_space % 2

            local label_str = string.rep(SPACE, spacing + space_remaining) .. curr_label .. string.rep(SPACE, spacing)
            info_label = info_label .. Config.Char_Bar_Side .. label_str .. Config.Char_Bar_Side

            curr_label = label
            prev_pos = pos
        end
    end

    return info_label
end


--- Add x-axis information (hours and days)
---@param parsed_pricing table
---@param home_energy_data table
local function bottom_info(parsed_pricing, home_energy_data)
    local x_axis = string.rep(Config.Char_Bar_Top, curr_price_info.h_scaling * #home_energy_data)
    table.insert(parsed_pricing, x_axis)


    local info_keys = get_info_keys(home_energy_data)
    table.insert(parsed_pricing, info_keys)


    local info_labels = get_info_labels(home_energy_data)
    table.insert(parsed_pricing, info_labels)
end


--- Add energy pricing bars
---@param parsed_pricing table
---@param home_energy_data homes_data
local function bar_data(parsed_pricing, home_energy_data)
    for i = 0, curr_price_info.y_space, 1 do
        local line = EMPTY
        local price_curr_line = curr_price_info.y_space - i

        for hour_index, data in ipairs(home_energy_data) do
            local curr_price = tonumber(math.floor(data.value * curr_price_info.v_scaling)) or -1

            -- Empty space
            if price_curr_line > curr_price then
                line = line .. string.rep(SPACE, curr_price_info.h_scaling)
                goto continue
            end

            -- Max energy bar price
            if price_curr_line == curr_price then
                line = line .. string.rep(Config.Char_Bar_Top, curr_price_info.h_scaling)
                goto continue
            end


            -- Alternate mid section character
            local mid_section = SPACE
            if hour_index % 2 == 0 then mid_section = Config.Char_Bar_Inside end


            -- Add left side
            local add_line = left_bar_up(home_energy_data, price_curr_line, hour_index, curr_price, mid_section)
            line = line .. add_line


            -- Add mid section
            local space_to_fill = curr_price_info.h_scaling - #add_line
            if space_to_fill > 1 then
                line = line .. string.rep(mid_section, space_to_fill - 1)
            end


            -- Add right side
            add_line = right_bar_down(home_energy_data, price_curr_line, hour_index, curr_price, mid_section)
            line = line .. add_line


            ::continue::
        end

        table.insert(parsed_pricing, line)
    end
end


--- Calculate the price based on the current line index
---@param curr_index integer
---@return integer
M.get_price_curr_line = function(curr_index)
    local price_curr_line = curr_price_info.y_space - curr_index + Config.Height_Offset - 1
    price_curr_line = math.floor(price_curr_line / (curr_price_info.v_scaling / CENTS_A_EURO))
    return price_curr_line
end


--- Return data with y_axis information
---@param parsed_pricing any
---@return table parsed_diagram
local function add_y_axis(parsed_pricing)
    local parsed_diagram = {}
    local price_prev_line = 0
    local num_step = 10
    local space_y_axis = 5

    for i, line in ipairs(parsed_pricing) do
        local price_curr_line = M.get_price_curr_line(i)

        if price_curr_line < 0 then
            table.insert(parsed_diagram, string.rep(SPACE, space_y_axis) .. Config.Char_Bar_Side .. line)
            goto continue
        end

        if price_curr_line % num_step ~= 0 then
            local missed_number = math.floor(price_prev_line / num_step) - math.floor(price_curr_line / num_step) > 0
            missed_number = missed_number and price_prev_line % num_step ~= 0

            if not missed_number then
                table.insert(parsed_diagram, string.rep(SPACE, space_y_axis) .. Config.Char_Bar_Side .. line)
                goto continue
            end
        end


        line = pad_left(price_curr_line, SPACE, space_y_axis - 2) .. SPACE .. DASH .. Config.Char_Bar_Side .. line
        table.insert(parsed_diagram, line)

        ::continue::
        price_prev_line = price_curr_line
    end
    return parsed_diagram
end


--- Convert energy pricing data
---@param home_energy_data table
---@return table
M.convert_data = function(home_energy_data, config, width, height)
    Config = config
    win_width = width
    win_height = height


    set_price_info(home_energy_data)

    local parsed_pricing = {}

    -- Add energy pricing bars
    bar_data(parsed_pricing, home_energy_data)

    -- Add x-axis information
    bottom_info(parsed_pricing, home_energy_data)

    -- Add y-axis information
    parsed_pricing = add_y_axis(parsed_pricing)

    return parsed_pricing
end


return M
