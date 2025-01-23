local floating = require("tibber.floating")

local M = {}


--- Toggle last opened floating window
M.toggle_window = function()
    floating.toggle_window()
end


return M
