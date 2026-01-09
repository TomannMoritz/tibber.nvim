local M = {}

local START_SCOPE = '{'
local END_SCOPE = '}'

local START_BRACKET = '%['
local END_BRACKET = '%]'

local LEAF_NODE = "{}"
local QUOTE = '"'
local COLON = ':'
local EMPTY = ""


--- Calculate a list of start and end positions for the next scope layer
--- - Start positions mark the ENTRY point to the next layer
--- - End positions mark the EXIT point back to the current layer
--- Returns an ordered table with a start and end position for each next scope layer
---@param layer string
---@return table
local function get_layer_positions(layer)
    local positions = {}
    local depth = 0

    for i = 1, #layer do
        local char = string.sub(layer, i, i)

        if char == START_SCOPE then
            if depth == 0 then
                table.insert(positions, i)
            end

            depth = depth + 1
        end

        if char == END_SCOPE then
            depth = depth - 1

            if depth == 0 then
                table.insert(positions, i)
            end
        end
    end

    return positions
end


--- Extract the first text inside two double quotes
---@param text string
---@return string
local function get_inside_quotes(text)
    local start_index = string.find(text, QUOTE)
    if start_index == nil then return EMPTY end

    -- remove quote character
    start_index = start_index + #QUOTE

    local sub_text = string.sub(text, start_index, -1)
    local end_index = string.find(sub_text, QUOTE)
    if end_index == nil then return EMPTY end

    -- remove quote character
    end_index = start_index - #QUOTE + end_index - #QUOTE

    return string.sub(text, start_index, end_index)
end


--- Extract and insert a (key, value) pair from the text into the table t
---@param t table
---@param text string
local function insert_data_pair(t, text)
    local index = string.find(text, COLON)
    if index == nil then
        table.insert({})
        return
    end

    local key = string.sub(text, 0, index - 1)
    key = get_inside_quotes(key)

    local value = string.sub(text, index + 1, -1)
    t[key] = value
end


--- Parse json data into lua tables
---@param t table
---@param data string
local function parse(t, data)
    local is_leaf_node = data == LEAF_NODE
    if is_leaf_node then return end

    -- remove previous layer scope
    data = string.sub(data, 2, -2)

    local positions = get_layer_positions(data)
    local is_last_layer = #positions == 0

    if is_last_layer then
        insert_data_pair(t, data)
        return
    end

    local prev_start_pos = 0
    for i = 1, #positions, 2 do
        local start_pos = positions[i]
        local end_pos = positions[i + 1]

        local next_data = string.sub(data, start_pos, end_pos)

        -- update table
        local layer_label = string.sub(data, prev_start_pos, start_pos - 1)
        layer_label = get_inside_quotes(layer_label)
        local next_table = {}

        if layer_label == EMPTY then
            table.insert(t, next_table)
        else
            t[layer_label] = next_table
        end

        parse(next_table, next_data)
        prev_start_pos = end_pos + 1
    end
end


--- Parse json data into a lua table
---@param data string
---@return table
M.parse = function(data)
    local lua_table = {}

    -- repalce json array scopes
    data = string.gsub(data, START_BRACKET, START_SCOPE)
    data = string.gsub(data, END_BRACKET, END_SCOPE)

    parse(lua_table, data)
    return lua_table
end


return M
