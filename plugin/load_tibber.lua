-- Set user commands
vim.api.nvim_create_user_command("TibberToggle", function(opts)
    local requery = opts.args == "true"

    require("tibber").toggle_window(requery)
end, {
        nargs = "?", -- zero or one argument
        complete = function()
            return { "true", "false" } -- Auto completion suggestions
        end,
        desc = "Toggle floating window with energy prices"
    }
)


vim.api.nvim_create_user_command("TibberLoad", function(opts)
    local file_path = opts.args

    require("tibber").toggle_load_data(file_path)
end, {
        nargs = 1,
        complete = "file", -- file and directory paths
        desc = "Toggle floating window with loaded energy prices"
    }
)

