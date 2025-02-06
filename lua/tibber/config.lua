local M = {}


---@class Tibber.Config
---@field Win_Width_Percentage integer
---@field Win_Height_Percentage integer
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
    Win_Width_Percentage = 100,     -- Floating window width as percentage of total width
    Win_Height_Percentage = 100,    -- Floating window height as percentage of total height
    Min_Bar_Height = 70,            -- Minimum covered price range
    Min_Bar_Width = 2,              -- Minimum width of each price/hour
    Height_Offset = 3,              -- Number of empty rows above the maximum price
    Char_Bar_Inside = ".",          -- Filling bar character
    Char_Bar_Side = "|",            -- Side bar character
    Char_Bar_Top = "_",             -- Top bar character
    Pricing = {
        Low_Min = 0,                -- Minimum energy price to label as LOW pricing
        Mid_Min = 25,               -- Minimum energy price to label as MID pricing
        High_Min = 45,              -- Minimum energy price to label as HIGH pricing
        Extreme_Min = 65            -- Minimum energy price to label as EXTREME pricing
    },
    Pricing_Groups = {
        Tibber_Low = { fg = '#00b300', bold = true},    -- Highlighting of LOW pricing labels
        Tibber_Mid = { fg = '#ffb347', bold = true},    -- Highlighting of MID pricing labels
        Tibber_High = { fg = '#ff6961', bold = true},   -- Highlighting of HIGH pricing labels
        Tibber_Extreme = { fg = '#b19cd9', bold = true} -- Highlighting of EXTREME pricing labels
    }
}


--- Return a value in the range (min, max)
---@param value integer
---@param min integer
---@param max integer
---@return integer
local function clamp(value, min, max)
    value = math.max(value, min)
    value = math.min(value, max)
    return value
end


--- Merge user config with the default config
---@param user_config any
M.set_config = function(user_config)
    if user_config == nil then print("[!] Invalid config") end
    user_config = user_config or {}

    M.Config = vim.tbl_deep_extend("force", M.Config, user_config)

    M.Config.Win_Width_Percentage = clamp(M.Config.Win_Width_Percentage, 0, 100)
    M.Config.Win_Height_Percentage = clamp(M.Config.Win_Height_Percentage, 0, 100)

    M.Config.Min_Bar_Height = math.max(M.Config.Min_Bar_Height, 10)
    M.Config.Min_Bar_Width = math.max(M.Config.Min_Bar_Width, 2)
    M.Config.Height_Offset = math.max(M.Config.Height_Offset, 0)

    M.Config.Pricing.Low_Min = math.max(M.Config.Pricing.Low_Min, 0)
    M.Config.Pricing.Mid_Min = math.max(M.Config.Pricing.Mid_Min, M.Config.Pricing.Low_Min)
    M.Config.Pricing.High_Min = math.max(M.Config.Pricing.High_Min, M.Config.Pricing.Mid_Min)
    M.Config.Pricing.Extreme_Min = math.max(M.Config.Pricing.Extreme_Min, M.Config.Pricing.High_Min)
end


return M
