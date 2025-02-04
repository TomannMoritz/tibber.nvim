local M = {}


---@class Tibber.Config
---@field Min_Bar_Height integer
---@field Min_Bar_Width integer
---@field Height_Offset integer
---@field Char_Bar_Inside string
---@field Char_Bar_Side string
---@field Char_Bar_Top string
---@field Pricing Tibber.Config.Pricing
---@field Pricing_Groups Tibber.Config.Pricing_Groups


---@class Tibber.Config.Pricing
---@field Low_Min integer
---@field Mid_Min integer
---@field High_Min integer
---@field Extreme_Min integer


---@class Tibber.Config.Pricing_Groups
---@field Tibber_Low table
---@field Tibber_Mid table
---@field Tibber_High table
---@field Tibber_Extreme table


---@type Tibber.Config
M.Config = {
    Min_Bar_Height = 70,    -- Minimum covered price range
    Min_Bar_Width = 2,      -- Minimum width of each price/hour
    Height_Offset = 3,      -- Number of empty rows above the maximum price
    Char_Bar_Inside = ".",
    Char_Bar_Side = "|",
    Char_Bar_Top = "_",
    Pricing = {
        Low_Min = 0,
        Mid_Min = 25,
        High_Min = 45,
        Extreme_Min = 65
    },
    Pricing_Groups = {
        Tibber_Low = { fg = '#00b300', bold = true},
        Tibber_Mid = { fg = '#ffb347', bold = true},
        Tibber_High = { fg = '#ff6961', bold = true},
        Tibber_Extreme = { fg = '#b19cd9', bold = true}
    }
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

    M.Config.Pricing.Low_Min = math.max(M.Config.Pricing.Low_Min, 0)
    M.Config.Pricing.Mid_Min = math.max(M.Config.Pricing.Mid_Min, M.Config.Pricing.Low_Min)
    M.Config.Pricing.High_Min = math.max(M.Config.Pricing.High_Min, M.Config.Pricing.Mid_Min)
    M.Config.Pricing.Extreme_Min = math.max(M.Config.Pricing.Extreme_Min, M.Config.Pricing.High_Min)
end


return M
