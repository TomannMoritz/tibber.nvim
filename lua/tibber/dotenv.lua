local M = {}

DOTENV_LABEL = "env"

DOTENV_FILE_PATH = "/.config/.env"
DOTENV_SEPARATOR = "="

TIBBER_API_TOKEN_KEY = "TIBBER_API_TOKEN"
TIBBER_API_URL_KEY = "TIBBER_API_URL"

KEYS = {TIBBER_API_TOKEN_KEY, TIBBER_API_URL_KEY}


--- Load and store required env data
M.load = function()
    local dot_env = {}

    local home_path = os.getenv("HOME")
    io.input(home_path .. DOTENV_FILE_PATH)

    while true do
        local line = io.read("*line")
        local end_of_file = line == nil
        if end_of_file then break end

        local split_index = string.find(line, DOTENV_SEPARATOR)
        if split_index == nil then
            goto continue
        end

        local key = string.sub(line, 1, split_index - #DOTENV_SEPARATOR)
        local value = string.sub(line, split_index + #DOTENV_SEPARATOR, -1)

        for _, key_label in ipairs(KEYS) do
            if key_label == key then
                dot_env[key] = value
            end
        end

        ::continue::
    end

    -- default options
    -- set default tibber api url
    dot_env[TIBBER_API_URL_KEY] = dot_env[TIBBER_API_URL_KEY] or "https://api.tibber.com/v1-beta/gql"

    -- reset/clear loaded environment
    M[DOTENV_LABEL] = dot_env
end


--- Return the stored API TOKEN if available
--- @return string|nil api_token
M.get_api_token = function()
    local invalid_env = M[DOTENV_LABEL] == nil
    if invalid_env then return nil end

    local missing_key = M[DOTENV_LABEL][TIBBER_API_TOKEN_KEY] == nil
    if missing_key then return nil end

    return M[DOTENV_LABEL][TIBBER_API_TOKEN_KEY]
end


--- Return the stored API URL if available
---@return string|nil api_url
M.get_api_url = function()
    local invalid_env = M[DOTENV_LABEL] == nil
    if invalid_env then return nil end

    local missing_key = M[DOTENV_LABEL][TIBBER_API_URL_KEY] == nil
    if missing_key then return nil end

    return M[DOTENV_LABEL][TIBBER_API_URL_KEY]
end


--- Check if the environment is set
---@return boolean is_valid
M.is_valid_env = function()
    local valid_api_token = M.get_api_token() ~= nil
    local valid_api_url = M.get_api_url() ~= nil

    return valid_api_token and valid_api_url
end


--- Log env information (missing keys)
M.log_env = function()
    print("[Info] Tibber.nvim")
    local env_path = os.getenv("HOME") .. DOTENV_FILE_PATH
    local info_text = "\t- Fix: %s in `%s`"

    local api_token = M[DOTENV_LABEL][TIBBER_API_TOKEN_KEY]
    if api_token == nil then
        print("\n[!] No Tibber API Token specified")
        print(string.format(info_text, TIBBER_API_TOKEN_KEY, env_path))
    end

    local tibber_url = M[DOTENV_LABEL][TIBBER_API_URL_KEY]
    if tibber_url == nil then
        print("\n[!] No Tibber API URL specified")
        print(string.format(info_text, TIBBER_API_URL_KEY, env_path))
    end
end


return M
