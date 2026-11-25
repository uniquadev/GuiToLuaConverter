local Selection = game:GetService("Selection");
local CoreGui = game:GetService("CoreGui");

local Utils = require(script.Parent:WaitForChild("utils"));
getfenv(Utils.IsLocal)["plugin"] = plugin;
local RbxApi = require(script.Parent:WaitForChild("rbxapi"));
local G2L = require(script.Parent:WaitForChild("core"));
local Alerts = require(script.Parent:WaitForChild("alerts"));

local DEBUG = Utils.IsLocal();
local TITLE = "GuiToLua";

local Screen = Instance.new("ScreenGui", CoreGui);
local Toolbar = plugin:CreateToolbar(TITLE);
local ConvertBtn = Toolbar:CreateButton(
    "Start Conversion", "Convert the selected GUI", "rbxassetid://3526632592"
);
local DebugBtn = DEBUG and Toolbar:CreateButton(
    "Debug", "Start a debug workflow", "rbxassetid://4525004810"
);

local function Convert()
    if not Utils.HasWriteAccess() then
        Alerts.Error(Screen, TITLE, "Please give me write access to scripts");
        return;
    end;

    local SelectedParts = Selection:Get();
    local Selected = SelectedParts[1];

    if not Selected or (not Selected:IsA("LayerCollector") and not Selected:IsA("GuiBase2d")) then
        Alerts.Warn(Screen, TITLE, "Please select a GUI instance (ScreenGui, SurfaceGui, BillboardGui, or GuiObject)");
        return;
    end;

    ConvertBtn.Enabled = false;

    local Res = G2L.Convert(Selected);
    local Out = Utils.WriteConvertionRes(Res);

    Selection:Set({Out});
    plugin:OpenScript(Out);
    Alerts.Success(Screen, TITLE, ("%s successfully converted"):format(Res.Gui.Name));
    ConvertBtn.Enabled = true;
end;

local function PropertiesCheck()
    local Members = RbxApi.GetProperties("TextLabel");
    local Dummy = RbxApi.GetDummy("TextLabel");
    assert(Members, "Can't retrieve TextLabel properties.");
    assert(Dummy, "Dummy not instantiated.");
    assert(Members["Text"], "TextLabel.Text not found.");
    assert(Members["Text"].Value == Dummy.Text, ("TextLabel.Text, %s not EQ to %s"):format(
        tostring(Members["Text"].Value), tostring(Dummy.Text)
    ));
    Alerts.Info(Screen, TITLE, "ROBLOX-API working");
end;

ConvertBtn.Click:Connect(Convert);

if DebugBtn then
    DebugBtn.Click:Connect(PropertiesCheck);
end;
