-- FLOW
-- => Convert(Gui)
-- => LoadDescendants(Res)
--  * Loop all descendants and store them in a reg
-- => WriteInstances(Res) 
--  * Write all instances as long with their properties
-- => WriteScripts(Res)
--  * Write all scripts routines with their env
-- => WriteLogo(Res)
-- return

--// REQUIRES \\--
local RbxApi = require(script.Parent.rbxapi)

--// CONST \\--
local FORMAT_NEW = 
[[
%s["%s"] = Instance.new("%s");
%s

]]; -- %s = Settings.RegName, %s = Id, %s = ClassName, %s = Properties

--// STRUCT \\--

export type RegInstance = {
    Id: string,
    Instance: Instance,
    Parent: RegInstance
}

export type ConvertionRes = {
    Gui: ScreenGui,
    Settings: Settings,
    Errors: {[number]: string},
    Source: string,
    _INST: {[number]: RegInstance},
    _LUA: {LocalScript | ModuleScript} -- hold Gui's local scripts
}

export type Settings = {
    RegName: string,
    Comments: boolean,
    Logo: boolean
}

--// CORE \\--

local function DefaultSettings() : Settings
    return {
        RegName = 'Luazifier',
        Comments = true,
        Logo = true
    };
end

-- Load descendants and order them in a flatted tree array, in order to provide a y(x) convertion
local function LoadDescendants(Res:ConvertionRes, Inst:Instance, Parent:RegInstance) : nil
    -- register instance
    local Size = #Res._INST+1;
    local RegInst = {
        Parent = Parent,
        Instance = Inst,
        Id = ('%x'):format(Size); -- hex format simple unique id
    };
    Res._INST[Size] = RegInst;
    -- check if local script
    if Inst:IsA('LocalScript') or Inst:IsA('ModuleScript') then
        Res._LUA[#Res._LUA+1] = RegInst;
    end
    -- loop children
    for Idx, Child in next, Inst:GetChildren() do
        LoadDescendants(Res, Child, RegInst) -- recursive time 8)
    end;
end;

local function GetProperties(Res:ConvertionRes, Inst:RegInstance) : string
    local Properties = '';
    local Members = RbxApi.GetProperties(Inst.Instance.ClassName);
    for Member, DefaultValue in pairs(Members) do
        -- special case as we have to get the id to reference the right parent
        if Member == 'Parent' then
            if Inst.Parent == nil then -- gui case
                -- TODO: let user choice wich parent use for the ScreenGui from Settings
                Properties = Properties .. ('%s["%s"].Parent = game:GetService("StarterGui");\n'):format(
                    Res.Settings.RegName, Inst.Id
                );
            else
                Properties = Properties .. ('%s["%s"].Parent = %s["%s"];\n'):format(
                    Res.Settings.RegName, Inst.Id,
                    Res.Settings.RegName, Inst.Parent.Id
                );
            end
        -- default property case
        else
            local CanSkip = false;
            -- skip if default value is set
            local Integrity = pcall(function()
                CanSkip = Inst.Instance[Member] == DefaultValue;
            end);
            if CanSkip or not Integrity then
                continue;
            end
            -- set property
            Properties = Properties .. ('%s["%s"]["%s"] = %s;\n'):format(
                Res.Settings.RegName, Inst.Id, Member,
                "'TODO'"
            );
        end;
    end;
    return Properties;
end;

local function WriteInstances(Res:ConvertionRes)
    for _, Inst in next, Res._INST do
        -- set comment
        local Comment = '';
        if Res.Settings.Comments then
            Comment = '-- ' .. Inst.Instance:GetFullName() .. '\n';
        end
        -- write instance
        Res.Source =  Res.Source .. Comment.. FORMAT_NEW:format(
            Res.Settings.RegName,
            Inst.Id,
            Inst.Instance.ClassName,
            GetProperties(Res, Inst)
        );
    end
end;

local function Convert(Gui:ScreenGui, Settings:Settings?) : ConvertionRes
    Settings = Settings or DefaultSettings();
    local Res : ConvertionRes = {
        Gui = Gui,
        Settings = Settings,
        Errors = {},
        Source = '',
        _INST = {},
        _LUA = {}
    };
    Res.Source = ('local %s = {};\n'):format(Settings.RegName);
    LoadDescendants(Res, Gui, nil);
    WriteInstances(Res);
    return Res;
end;

return {
    Convert = Convert
}