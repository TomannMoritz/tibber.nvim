# tibber.nvim

Neovim plugin for displaying current energy information.
Energy prices are queried via the [Tibber API](https://developer.tibber.com/). <br>
Therefor a Tibber Account/ API Key is required.


## Installation
Install with your package manager with the required dependencies.

### Dependencies
- [json-lua](https://github.com/tiye/json-lua)
- [lua-dotenv](https://github.com/rxi/json.lua)

```bash
luarocks install json-lua
luarocks install lua-dotenv
```

<details>
    <summary><strong>packer.nvim</strong></summary>

```lua
use "TomannMoritz/tibber.nvim"
```
</details>


## Setup
1. Store these values required by the **Tibber API** in the `/.config/.env` file 
```.env
# .env
TIBBER_API_TOKEN=
TIBBER_URL= # Optional
```

2. Setup your own config (*Optional*)

**Default configuration:**
```lua
require("tibber").setup({
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
})
```

3. Setup a keymapping
```lua
vim.keymap.set("n", "<leader>te", "<cmd>lua require('tibber').toggle_window()<CR>", { desc = "[T]oggle Tibber [E]nergy" })
```

