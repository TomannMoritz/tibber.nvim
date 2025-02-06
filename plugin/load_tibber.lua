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

