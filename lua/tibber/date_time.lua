local M = {}

-- Date Time format:
--   (date)T(time)
SEPARATOR = 'T'

-- Date format:
--   YYYY-MM-DD
M.DATE_SEPARATOR = '-'
ZERO = '0'

YEAR_POS = 4
MONTH_POS = 2
DAY_POS = 2


-- Time format:
--   HH:MM:SS.mmm+HH:MM
M.TIME_SEPARATOR = ':'

HOUR_POS = 2
MIN_POS = 2
SEC_POS = 2

MIL_POS = 4
TIME_ZONE_POS = 6


---@class date
---@field year integer
---@field month integer
---@field day integer


---@class time
---@field hour integer
---@field min integer
---@field sec integer


--- Split a string at the left and right most separator
---@param text any
---@param separator any
---@return string|nil
---@return string|nil
---@return string|nil
local function split_twice(text, separator)
    local first_split_pos, _ = string.find(text, separator)
    local second_split_pos, _ = string.find(string.reverse(text), separator)
    second_split_pos = #text - second_split_pos + 1

    if first_split_pos == nil or first_split_pos == second_split_pos then return nil, nil, nil end

    local first_part = string.sub(text, 1, first_split_pos - #separator)
    local second_part = string.sub(text, first_split_pos + #separator, second_split_pos - #separator)
    local third_part = string.sub(text, second_split_pos + #separator, -1)

    return first_part, second_part, third_part
end


--- Convert a string into the date datatype
---@param date_str string|nil
---@return date|nil
M.str_to_date = function(date_str)
    if date_str == nil then return nil end

    local date_len = YEAR_POS + #M.DATE_SEPARATOR + MONTH_POS + #M.DATE_SEPARATOR + DAY_POS
    if #date_str ~= date_len then return nil end

    local year_str, month_str, day_str = split_twice(date_str, M.DATE_SEPARATOR)

    local year_num = tonumber(year_str)
    local month_num = tonumber(month_str)
    local day_num = tonumber(day_str)

    if #year_str ~= YEAR_POS or year_num == nil then return nil end
    if #month_str ~= MONTH_POS or month_num == nil then return nil end
    if #day_str ~= DAY_POS or day_num == nil then return nil end

    ---@type date
    local date = {
        year = year_num,
        month = month_num,
        day = day_num
    }

    return date
end


--- Convert the date datatype into a string
---@param date date|nil
---@return string|nil date_str
M.date_to_str = function(date)
    if date == nil then return nil end

    local year_str = tostring(date.year)
    local month_str = tostring(date.month)
    local day_str = tostring(date.day)

    year_str = string.rep(ZERO, YEAR_POS - #year_str) .. year_str
    month_str = string.rep(ZERO, MONTH_POS - #month_str) .. month_str
    day_str = string.rep(ZERO, DAY_POS - #day_str) .. day_str

    local date_str = year_str .. M.DATE_SEPARATOR .. month_str .. M.DATE_SEPARATOR .. day_str
    return date_str
end


--- Convert a string into the time datatype
---@param time_str string|nil
---@return time|nil
M.str_to_time = function(time_str)
    if time_str == nil then return nil end

    local time_len = HOUR_POS + #M.TIME_SEPARATOR + MIN_POS + #M.TIME_SEPARATOR + SEC_POS
    if #time_str ~= time_len then return nil end

    local hour_str, min_str, sec_str = split_twice(time_str, M.TIME_SEPARATOR)

    local hour_num = tonumber(hour_str)
    local min_num = tonumber(min_str)
    local sec_num = tonumber(sec_str)

    if #hour_str ~= HOUR_POS or hour_num == nil then return nil end
    if #min_str ~= MIN_POS or min_num == nil then return nil end
    if #sec_str ~= SEC_POS or sec_num == nil then return nil end

    ---@type time
    local time = {
        hour = hour_num,
        min = min_num,
        sec = sec_num
    }

    return time
end


--- Convert the time datatype into a string
---@param time time|nil
---@return string|nil time
M.time_to_str = function(time)
    if time == nil then return nil end

    local hour_str = tostring(time.hour)
    local min_str = tostring(time.min)
    local sec_str = tostring(time.sec)

    hour_str = string.rep(ZERO, HOUR_POS - #hour_str) .. hour_str
    min_str = string.rep(ZERO, MONTH_POS - #min_str) .. min_str
    sec_str = string.rep(ZERO, DAY_POS - #sec_str) .. sec_str

    local time_str = hour_str .. M.TIME_SEPARATOR .. min_str .. M.TIME_SEPARATOR .. sec_str
    return time_str
end


--- Extract date and time datatypes from a string
---@param date_time string
---@return date|nil date
---@return time|nil time
M.split_date_time = function(date_time)
    local split_pos, _ = string.find(date_time, SEPARATOR)
    local rev_split_pos, _ = string.find(string.reverse(date_time), SEPARATOR)
    rev_split_pos = #date_time - rev_split_pos + 1

    local invalid_date_time = split_pos == nil or split_pos ~= rev_split_pos
    if invalid_date_time then return nil, nil end

    local date_str = string.sub(date_time, 1, split_pos - #SEPARATOR)
    local date = M.str_to_date(date_str)

    local time_str = string.sub(date_time, split_pos + #SEPARATOR, -1)
    local time_cutoff = MIL_POS + TIME_ZONE_POS
    local filtered_time_str = string.sub(time_str, 1, - time_cutoff - 1)
    local time = M.str_to_time(filtered_time_str)

    return date, time
end

return M
