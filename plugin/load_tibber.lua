-- user commands

local white_space = "%s+"


--- Filter empty strings in table
---@param t table
---@return table filtered_table
local function filter_empty_str(t)
    local filtered_table = {}

    for _, str in ipairs(t) do
        if str ~= "" then
            table.insert(filtered_table, str)
        end
    end

    return filtered_table
end


--- Custom multi argument auto complete function
---@param completion_list table
---@return function
local function custom_complete(completion_list)
    return function (ArgLead, CmdLine, CursorPos)
        local args = vim.split(CmdLine, white_space)
        local arg_pos = #args - 1

        if completion_list == nil then return {} end
        if #completion_list < arg_pos then return {} end

        return completion_list[arg_pos]
    end
end


local api_completion_list = {
    {"HOURLY", "QUARTERLY"},
    {"true", "false"}
}


-- Create user commands
vim.api.nvim_create_user_command("TibberToggleAPI", function(opts)
    local args = vim.split(opts.args, white_space)
    args = filter_empty_str(args)

    -- first argument: query resolution
    local resolution = nil
    if #args >= 1 then
        resolution = args[1]
    end

    -- second argument: requery API
    local requery = #args >= 2 and args[2] == "true"

    -- lazy-load module
    require("tibber").toggle_api(resolution, requery)
end, {
        nargs = "*", -- zero or many arguments
        complete = custom_complete(api_completion_list),
        desc = "Toggle floating window - API energy prices"
    }
)


vim.api.nvim_create_user_command("TibberToggleFile", function(opts)
    local file_path = opts.args

    -- lazy-load module
    require("tibber").toggle_file(file_path)
end, {
        nargs = 1,
        complete = "file", -- file and directory paths
        desc = "Toggle floating window - File energy prices"
    }
)

