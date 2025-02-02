local M = {}


---@class Tibber.Config
---@field Min_Bar_Height integer
---@field Min_Bar_Width integer
---@field Height_Offset integer
---@field Char_Bar_Inside string
---@field Char_Bar_Side string
---@field Char_Bar_Top string


---@type Tibber.Config
M.Config = {
    Min_Bar_Height = 70,    -- Minimum covered price range
    Min_Bar_Width = 2,      -- Minimum width of each price/hour
    Height_Offset = 3,      -- Number of empty rows above the maximum price
    Char_Bar_Inside = ".",
    Char_Bar_Side = "|",
    Char_Bar_Top = "_"
}



--- Merge user config with the default config
---@param user_config any
M.set_config = function(user_config)
    if user_config == nil then print("[!] Invalid config") end
    user_config = user_config or {}

    M.Config = vim.tbl_deep_extend("force", M.Config, user_config)

    M.Config.Min_Bar_Height = math.max(M.Config.Min_Bar_Height, 10)
    M.Config.Min_Bar_Width = math.max(M.Config.Min_Bar_Width, 2)
    M.Config.Height_Offset = math.max(M.Config.Height_Offset, 0)
end


return M
