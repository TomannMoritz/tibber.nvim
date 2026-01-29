local M = {}

local START_SCOPE = '{'
local END_SCOPE = '}'

local START_BRACKET = '%['
local END_BRACKET = '%]'

local QUOTE = '"'
local COLON = ':'
local COMMA = ','
local EMPTY = ""

local STARTING_DEPTH = 1
local SEPARATOR = 1


--- Calculate a list of depth and positions based on scope layers
--- - Brackets increase and decrease the current scope
--- - Commas indicate more key/value pairs within the same scope level
--- Returns ordered tables for depth and position data
---@param data string
---@return table|nil layer_depths
---@return table|nil layer_positions
local function get_layer_positions(data)
    local invalid_json = string.find(data, START_SCOPE) == nil
    if invalid_json then return nil, nil end

    local layer_depths = {}
    local layer_positions = {}

    local depth = 0

    for i = 1, #data do
        local char = string.sub(data, i, i)

        if char == COMMA then
            table.insert(layer_depths, depth)
            table.insert(layer_positions, i)
        end

        if char == START_SCOPE then
            depth = depth + 1

            table.insert(layer_depths, depth)
            table.insert(layer_positions, i)
        end

        if char == END_SCOPE then
            table.insert(layer_depths, depth)
            table.insert(layer_positions, i)

            depth = depth - 1
        end

        -- to many closing brackets
        invalid_json = depth < 0
        if invalid_json then return nil, nil end
    end

    -- missing closing brackets
    invalid_json = depth ~= 0
    if invalid_json then return nil, nil end

    return layer_depths, layer_positions
end


--- Extract the first text inside two double quotes
---@param text string
---@return string|nil
local function get_inside_quotes(text)
    local start_index, _ = string.find(text, QUOTE)
    if start_index == nil then return nil end

    -- remove quote character
    start_index = start_index + #QUOTE

    local sub_text = string.sub(text, start_index, -1)
    local end_index = string.find(sub_text, QUOTE)
    if end_index == nil then return nil end

    -- remove quote character
    end_index = start_index - #QUOTE + end_index - #QUOTE

    return string.sub(text, start_index, end_index)
end


--- Split a key/value pair into key and value
---@param data string
---@return string|nil key
---@return string value
local function split_data_pair(data)
    local sub_layer_position, _ = string.find(data, START_SCOPE)
    local colon_position = string.find(data, COLON)

    if colon_position == nil then
        return nil, data
    end

    if sub_layer_position ~= nil and sub_layer_position < colon_position then
        return nil, data
    end

    local key = string.sub(data, 1, colon_position - #COLON)
    local key_ = get_inside_quotes(key)

    local value = string.sub(data, colon_position + #COLON, -1)

    return key_, value
end


--- Insert key/value pair into table based on the specified key
---@param t table
---@param key string|nil
---@param value any
local function insert_with_without_key(t, key, value)
    if key == nil then
        table.insert(t, value)
    else
        t[key] = value
    end
end


--- Extract and insert a (key, value) pair from the text into the table t
---@param t table
---@param text string
local function insert_data_pair(t, text)
    local key, value = split_data_pair(text)

    local num_value = tonumber(value)
    local is_number = num_value ~= nil
    if is_number then
        insert_with_without_key(t, key, num_value)
        return
    end

    local str_value = get_inside_quotes(value) or value
    insert_with_without_key(t, key, str_value)
end


--- Parse json data recursively into a lua table
---@param t table
---@param data string
local function parse(t, data)
    local start_data, _ = string.find(data, START_SCOPE)
    local end_data, _ = string.find(string.reverse(data), END_SCOPE)
    if start_data == nil or end_data == nil then return end

    local empty_node = #data == 0
    if empty_node then return end

    local layer_depths, layer_positions = get_layer_positions(data)
    if layer_depths == nil or layer_positions == nil then return end

    local prev_pos = layer_positions[1] + SEPARATOR
    local to_deep = false

    for i, depth in ipairs(layer_depths) do
        if depth > STARTING_DEPTH then to_deep = true end

        local position = layer_positions[i]

        if depth == STARTING_DEPTH and prev_pos ~= position then
            local sub_data = string.sub(data, prev_pos, position - SEPARATOR)
            prev_pos = position + SEPARATOR

            if sub_data == EMPTY then goto continue end

            if not to_deep then
                insert_data_pair(t, sub_data)

            else
                local next_table = {}
                local key, value = split_data_pair(sub_data)

                if key == nil then
                    table.insert(t, next_table)
                    parse(next_table, sub_data)
                else
                    t[key] = next_table
                    parse(next_table, value)
                end
            end

            ::continue::
            to_deep = false
        end
    end
end


--- Parse json data into a lua table
---@param data string
---@return table|nil
M.parse = function(data)
    local lua_table = {}

    -- replace json array scopes
    data = string.gsub(data, START_BRACKET, START_SCOPE)
    data = string.gsub(data, END_BRACKET, END_SCOPE)

    local positions = get_layer_positions(data)
    local invalid_json = positions == nil
    if invalid_json then return nil end

    parse(lua_table, data)
    return lua_table
end


return M
