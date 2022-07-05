--// REQUIRES \\--
local Utils = require(script.Parent:WaitForChild("utils"));
local RbxApi = require(script.Parent:WaitForChild("rbxapi")); -- Debug purpose
--// GLOBALS \\--
local DEBUG = true;
-- Services
local Selection = game:GetService("Selection");

-- Plugin UI
local Toolbar = plugin:CreateToolbar("GuiToLuaConverter");
local ConvertBtn = Toolbar:CreateButton(
    "Start Convertion", "Convert the selected ScreenGui", "rbxassetid://3526632592"
);
local DebugBtn = DEBUG and Toolbar:CreateButton(
    "Debug", "Start a debug workflow", "rbxassetid://4525004810" -- orbital easteregg <3
);

-- Plugin Core
local function Convert()
    local SelectedParts = Selection:Get();
    local Selected : ScreenGui = SelectedParts[1];
    -- check if selected instance is a screen gui
    if (not Selected or Selected.ClassName ~= "ScreenGui") then
        warn("Please select a ScreenGui");
        return;
    end;
    -- out folder
    local OutFolder = Utils.GetOutFolder(Selected.Name);



    -- TODO: start convertion
    -- TODO: check errors
    -- TODO: instanciate a "ScreenGui.Name .. os.time"  disabled LocalScript in the out folder
    -- TODO: save script (since roblox doesn't let plugins write how many chars they want in a script
    -- it will require us to split the out code in more scripts and let the user copy paste them in one..
    -- ty roblox
    -- TODO: select the instanciated script
end;

--// DEBUG WORKFLOW \\--
local function PropertiesCheck()
    local Members = RbxApi.GetProperties('TextLabel');
    local Dummy = RbxApi.GetDummy('TextLabel');
    assert(Members, 'Can\'t retrive TextLabel properties.');
    assert(Dummy, 'Dummy not instanciated.');
    assert(Members['Text'], 'TextLabel.Text not found.');
    assert(Members['Text'] == Dummy.Text, ('TextLabel.Text not EQ to %s.'):format(Dummy.Text));
    print('ROBLOX-API working.')
end

-- Connections
ConvertBtn.Click:Connect(Convert);

if DebugBtn then
    DebugBtn.Click:Connect(PropertiesCheck);
end