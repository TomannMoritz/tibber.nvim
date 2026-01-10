local dotenv = require("lua-dotenv")
local json = require("tibber.json")


local M = {}


---@class homes_data
---@field homes table


---@type homes_data
local homes_data = {
    homes = {}
}


---@class environment
---@field TIBBER_URL string
---@field API_TOKEN string


---@type environment
local env = {
    API_TOKEN = "",
    TIBBER_URL = ""
}


--- Get the priceInfo body for the query
---@return string query_body
local query_price_info = function()
    local query_body = [[
        { "query": "{viewer { homes { currentSubscription { priceInfo { today { total }, tomorrow { total } } } } } }" } ]]

    return query_body
end


--- Get the cURL command to query the tibber api
---@param query_body string
---@return string
local curl_query = function(query_body)
    local curl_command = string.format([[
        curl -s -X POST -H "Authorization: %s" -H "Content-Type: application/json" -d '%s' %s]],
        env.API_TOKEN, query_body, env.TIBBER_URL)

    return curl_command
end



--- Combine energy data for today and tomorrow into one table
---@param priceInfo table
---@return table
M._combine_days = function(priceInfo)
    local energy_prices = {}
    -- Today
    if priceInfo.today ~= nil then
        for _, price in ipairs(priceInfo.today) do
            table.insert(energy_prices, price)
        end
    end

    -- Tomorrow
    if priceInfo.tomorrow ~= nil then
        for _, price in ipairs(priceInfo.tomorrow) do
            table.insert(energy_prices, price)
        end
    end

    return energy_prices
end


--- Create a lua table from the priceInfo json data
--- -> Filter out unnecessary json keys
---@param query_result string
local price_info_table = function(query_result)
    local decode = json.parse(query_result)

    local homes = decode.data.viewer.homes
    homes_data = { homes = {}}

    for _, home in ipairs(homes) do
        local energy_prices = M._combine_days(home.currentSubscription.priceInfo)
        table.insert(homes_data.homes, energy_prices)
    end
end


--- Get energy price data via the tibber api
---@return string
local query_price_data = function()
    local query_body = query_price_info()
    local curl_command = curl_query(query_body)

    local query_handle = io.popen(curl_command)

    if query_handle == nil then return "" end

    -- read the whole file
    local result = query_handle:read("*a")
    query_handle:close()

    return result
end


--- Check if the environment is set
---@return boolean is_valid
local valid_env = function()
    return env.API_TOKEN ~= "" and env.TIBBER_URL ~= ""
end


--- Load and set the environment variables from the dotenv file
local load_env = function()
    -- load variables from: ~/.config/.env
    dotenv.load_dotenv()

    local api_token = dotenv.get("TIBBER_API_TOKEN")
    if api_token == nil then print("[!] No Tibber API Token specified") end

    local tibber_url = dotenv.get("TIBBER_URL")
    if tibber_url == nil then print("[!] No Tibber URL specified") end

    env = {
        API_TOKEN = api_token or "",
        TIBBER_URL = tibber_url or "https://api.tibber.com/v1-beta/gql"
    }
end


--- Get energy price data
---@return homes_data|nil filtered_data
M.get_price_data = function()
    if not valid_env() then
        load_env()

        if not valid_env() then
            return nil
        end
    end

    local query_result = query_price_data()
    price_info_table(query_result)

    return homes_data
end


return M
