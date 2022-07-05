--// REQUIRES \\--
local Utils = require(script.Parent:WaitForChild("utils"));
getfenv(Utils.IsLocal)['plugin'] = plugin; -- roblox suck
local RbxApi = require(script.Parent:WaitForChild("rbxapi")); -- Debug purpose
local G2L = require(script.Parent:WaitForChild("core"));

--// GLOBALS \\--
local DEBUG = Utils.IsLocal();
-- Services
local Selection = game:GetService("Selection");

--// UI \\--
local Toolbar = plugin:CreateToolbar("GuiToLua");
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
    -- convert
    local Res = G2L.Convert(Selected);
    local Out = Utils.WriteConvertionRes(Res);
    -- select the out folder
    Selection:Set(Out:GetChildren());
    plugin:OpenScript(Out:FindFirstChildOfClass('LocalScript'));
end;

--// DEBUG WORKFLOW \\--
local function PropertiesCheck()
    local Members = RbxApi.GetProperties('TextLabel');
    local Dummy = RbxApi.GetDummy('TextLabel');
    assert(Members, 'Can\'t retrive TextLabel properties.');
    assert(Dummy, 'Dummy not instanciated.');
    assert(Members['Text'], 'TextLabel.Text not found.');
    assert(Members['Text'].Value == Dummy.Text, ('TextLabel.Text, %s not EQ to %s'):format(
        Members['Text'].Value, Dummy.Text
    ));
    print('ROBLOX-API working.')
end

-- Connections
ConvertBtn.Click:Connect(Convert);

if DebugBtn then
    DebugBtn.Click:Connect(PropertiesCheck);
end