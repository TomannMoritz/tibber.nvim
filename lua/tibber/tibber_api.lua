local dotenv = require("lua-dotenv")


local M = {}


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
        { "query": "{viewer { homes { currentSubscription { priceInfo { tomorrow { total } } } } } }" } ]]

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


--- Filter out unnecessary json keys
---@param query_result string
---@return string
local filter_price_info = function(query_result)
    local jq_filter = ".data.viewer.homes[].currentSubscription.priceInfo"
    local jq_command = string.format([[
    echo %q | jq %s]],
    query_result, jq_filter)

    local jq_handle = io.popen(jq_command)
    if jq_handle == nil then return "" end

    -- read the whole file
    local result = jq_handle:read("*a")
    jq_handle:close()

    return result
end


--- Get energy price data via the tibber api
---@return string
local query_price_data = function()
    local query_body = query_price_info()
    local curl_command = curl_query(query_body)

    local query_handle = io.popen(curl_command)
    print(vim.inspect(query_handle))

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
---@return string filtered_data
M.get_price_data = function()
    if not valid_env() then
        load_env()
        return M.get_price_data()
    end

    local query_result = query_price_data()
    local filtered_data = filter_price_info(query_result)

    return filtered_data
end


return M
