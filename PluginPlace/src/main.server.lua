-- Modules
-- Plugin UI
local Toolbar = plugin:CreateToolbar("GuiToLuaConverter");
local ConvertBtn = Toolbar:CreateButton("Start Convertion", "Convert the selected ScreenGui", "rbxassetid://3526632592");
-- Plugin Core
local function Convert()
    print('Hello World')
    -- TODO: check if ScreenGui selected
    -- TODO: make a GuiToLuaConverter folder in the workspace
    -- TODO: start convertion
    -- TODO: check errors
    -- TODO: instanciate a "ScreenGui.Name .. os.time"  disabled LocalScript in the out folder
    -- TODO: save script (since roblox doesn't let plugins write how many chars they want in a script
    -- it will require us to split the out code in more scripts and let the user copy paste them in one..
    -- ty roblox
    -- TODO: select the instanciated script
end;
-- Connections
ConvertBtn.Click:Connect(Convert);