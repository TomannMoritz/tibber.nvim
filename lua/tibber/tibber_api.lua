local dotenv = require("tibber.dotenv")
local json = require("tibber.json")
local date_time = require("tibber.date_time")

local M = {}
local DATA = "data"

local query_hourly = "HOURLY"
local query_quarterly = "QUARTERLY"

---@alias query_resolution `query_hourly` | `query_quarterly`


---@class homes_data
---@field homes energy_data[]


---@class energy_data
---@field title string|nil
---@field data (ele)[]

---@class ele
---@field value number
---@field key string|nil
---@field label string|nil


---@type homes_data
local homes_data = {
    homes = {
        data = {},
        title = nil
    }
}


--- Get the priceInfo body for the query
---@param resolution query_resolution
---@return string query_body
local query_price_info = function(resolution)
    local price_resolution_str = "priceInfo"

    if resolution == query_quarterly then
        price_resolution_str = price_resolution_str .. "(resolution: QUARTER_HOURLY)"
    end

    local query_body = [[ { "query": "{viewer { homes { currentSubscription { ]]
    query_body = query_body .. price_resolution_str
    query_body = query_body .. [[ { today { total startsAt }, tomorrow { total startsAt } } } } } }" } ]]

    return query_body
end


--- Get the cURL command to query the tibber api
---@param query_body string
---@return string
local curl_query = function(query_body)
    local api_token = dotenv.get_api_token() or ""
    local api_url = dotenv.get_api_url() or ""

    local curl_command = string.format([[
        curl -s -X POST -H "Authorization: %s" -H "Content-Type: application/json" -d '%s' %s]],
        api_token, query_body, api_url)

    return curl_command
end


--- Insert energy data (value, key, label)
---@param t ele[]
---@param data table
---@param resoultion query_resolution
---@return boolean success
local function insert_energy_data(t, data, resoultion)
    for _, values in ipairs(data) do
        local price = values.total
        local label = values.startsAt
        if price == nil or label == nil then return false end

        local date, time = date_time.split_date_time(label)
        local date_str = date_time.date_to_str(date)
        local time_str = date_time.time_to_str(time) or ""

        if resoultion == query_hourly then
            time_str = string.sub(time_str, 1, 2)
        end

        if resoultion == query_quarterly then
            time_str = string.sub(time_str, 1, 5)
        end

        table.insert(t, {value = price, key = time_str, label = date_str})
    end

    return true
end


--- Combine energy data for today and tomorrow into one table
---@param priceInfo table
---@param resolution query_resolution
---@return ele[]|nil data
M._combine_days = function(priceInfo, resolution)
    local data = {}

    -- Today
    if priceInfo.today ~= nil then
        if not insert_energy_data(data, priceInfo.today, resolution) then
            return nil
        end
    end

    -- Tomorrow
    if priceInfo.tomorrow ~= nil then
        if not insert_energy_data(data, priceInfo.tomorrow, resolution) then
            return nil
        end
    end

    return data
end


--- Create a lua table from the priceInfo json data
--- -> Filter out unnecessary json keys
---@param query_result string
---@param resolution query_resolution
---@return boolean success
local price_info_table = function(query_result, resolution)
    local decode = json.parse(query_result)
    if decode == nil then return false end

    -- query error
    if decode[DATA] == nil then
        print("[Tibber.nvim] [!] Failed query:\n" .. vim.inspect(decode))
        return false
    end

    local homes = decode.data.viewer.homes
    homes_data = {
        homes = {
            data = {},
            title = nil
        }
    }

    for _, home in ipairs(homes) do
        local energy_prices = M._combine_days(home.currentSubscription.priceInfo, resolution)
        table.insert(homes_data.homes, {data = energy_prices})
    end

    return true
end


--- Get energy price data via the tibber api
---@param resolution query_resolution
---@return string|nil result
local query_price_data = function(resolution)
    local query_body = query_price_info(resolution)
    local curl_command = curl_query(query_body)

    local query_handle = io.popen(curl_command)

    if query_handle == nil then return nil end

    -- read the whole file
    local result = query_handle:read("*a")
    query_handle:close()

    -- no data
    if #result == 0 then
        print("[Tibber.nvim] [!] No data received")
        print("\t- Check your internet connection")
        return nil
    end

    return result
end


--- Get energy price data
---@param resolution query_resolution|nil
---@return homes_data|nil filtered_data
M.get_price_data = function(resolution)
    if not dotenv.is_valid_env() then
        -- load variables from: ~/.config/.env
        local loaded_env = dotenv.load()
        if not loaded_env then return nil end

        if not dotenv.is_valid_env() then
            dotenv.log_env()
            return nil
        end
    end

    -- default resolution
    ---@type query_resolution
    resolution = resolution or query_hourly

    local query_result = query_price_data(resolution)
    if query_result == nil then return nil end

    local success = price_info_table(query_result, resolution)
    if not success then return nil end

    return homes_data
end


--- Check/Create valid energy data
---@param energy_data energy_data
---@return energy_data|nil valid_data
---@return string error_msg
M.get_valid_data = function(energy_data)
    local error_msg = ""
    if energy_data.data == nil then return nil, error_msg end

    local valid_data = {}
    local valid_energy_data = {
        title = energy_data.title,
        data = valid_data
    }

    for pos, ele in ipairs(energy_data.data) do
        local value = ele.value
        if value == nil or tonumber(value) == nil then
            error_msg = "[Tibber.nvim] [!] Invalid input value: \n"
            error_msg = error_msg .. "  Position: " .. pos
            error_msg = error_msg .. "\n  Value: " .. tostring(value)
            return nil, error_msg
        end

        local key = ele.key or ""
        local label = ele.label or ""
        local valid_ele = {
            value = tonumber(value),
            key = key,
            label = label
        }

        table.insert(valid_data, valid_ele)
    end

    return valid_energy_data, error_msg
end


return M
