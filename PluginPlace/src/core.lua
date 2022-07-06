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
local RbxApi = require(script.Parent.rbxapi);
local Utils = require(script.Parent.utils);
local Logo = script.Parent.logo.Value;

--// CONST \\--
local F_NEWINST = 
[[
%s["%s"] = Instance.new("%s", %s);
%s
]]; -- %s = Settings.RegName, %s = Id, %s = ClassName, %s = Parent, %s = Properties
local F_NEWLUA =
[[
local function %s()
    %s
end;
getfenv(%s)["script"] = %s["%s"];
task.spawn(%s);
]] -- %s = ClosureName, %s = ClosureName, %s = RegName, %s = Id, %s = ClosureName

local BLACKLIST = {
    Source = true,
    Parent = true
}

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
    _LUA: {RegInstance} -- hold Gui's local scripts
}

export type Settings = {
    RegName: string,
    Comments: boolean,
    Logo: boolean
}

--// CORE \\--

local function DefaultSettings() : Settings
    return {
        RegName = 'G2L',
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
    if Inst:IsA('LocalScript') then
        Res._LUA[#Res._LUA+1] = RegInst;
    end;
    -- loop children
    for Idx, Child in next, Inst:GetChildren() do
        LoadDescendants(Res, Child, RegInst) -- recursive time 8)
    end;
end;

local function GetProperties(Res:ConvertionRes, Inst:RegInstance) : string
    local Properties = '';
    local Members = RbxApi.GetProperties(Inst.Instance.ClassName);
    for Member, Default:RbxApi.ValueObject in pairs(Members) do
        -- special case skip
        if BLACKLIST[Member] then
            continue;         
        -- default property case
        else
            local Type;
            local CanSkip = false;
            -- skip if default value is set
            local Integrity = pcall(function()
                Type = typeof(Inst.Instance[Member]);
                CanSkip = Inst.Instance[Member] == Default.Value;
            end);
            if CanSkip or not Integrity then
                continue;
            end
            -- encode value
            local Raw = Inst.Instance[Member];
            local Value = '';
            if Type == 'string' then
                Value = '"' .. Raw .. '"';
            elseif Type == 'number' or Type == 'boolean' or Type:match('^Enum') then
                Value = tostring(Raw);
            elseif Type == 'Vector2' then
                Value = 'Vector2.new(' .. Raw.X .. ',' .. Raw.Y .. ')';
            elseif Type == 'Vector3' then
                Value = 'Vector3.new(' .. Raw.X .. ',' .. Raw.Y .. ',' .. Raw.Z .. ')';
            elseif Type == 'UDim2' then
                Value = 'UDim2.new(' .. Raw.X.Scale .. ',' .. Raw.X.Offset .. ',' 
                .. Raw.Y.Scale .. ',' .. Raw.Y.Offset .. ')';
            elseif Type == 'UDim' then
                Value = 'UDim.new(' .. Raw.Scale .. ',' .. Raw.Offset .. ')';
            elseif Type == 'Color3' then
                Value = 'Color3.new(' .. Raw.R .. ',' .. Raw.G .. ',' .. Raw.B .. ')';
            end
            -- set property
            if Value == '' then -- if value is not resolved
                if Utils.IsLocal() then
                    Properties = Properties .. '-- '; -- comment property to debug it
                else
                    continue; -- skip property
                end;
            end
            Properties =  Properties .. ('%s["%s"]["%s"] = %s;\n'):format(
                Res.Settings.RegName, Inst.Id,
                Member, Value
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
        -- solve parent
        local Parent = '';
        if Inst.Parent == nil then -- gui case
            -- TODO: let user choice wich parent use for the ScreenGui from Settings
            Parent = 'game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")';
        else
            Parent = ('%s["%s"]'):format(
                Res.Settings.RegName, Inst.Parent.Id
            ); -- we have to get the id to reference the right parent
        end
        -- write instance
        Res.Source =  Res.Source .. Comment.. F_NEWINST:format(
            Res.Settings.RegName,
            Inst.Id,
            Inst.Instance.ClassName,
            Parent,
            GetProperties(Res, Inst)
        );
    end
end;

local function WriteScripts(Res:ConvertionRes) -- TODO
    for _, Script in next, Res._LUA do
        -- skip case
        if Script.Instance.Disabled then
            continue;
        end
        local ClosureName = 'C_' .. Script.Instance.Name .. '_' .. Script.Id;
        -- set comment
        local Comment = '';
        if Res.Settings.Comments then
            Comment = '-- ' .. Script.Instance:GetFullName() .. '\n';
        end
        -- write
        Res.Source = Res.Source .. Comment .. F_NEWLUA:format(
            ClosureName, Script.Instance.Source:gsub('\n', '\n\t'), -- fix tabulation
            ClosureName, Res.Settings.RegName, Script.Id,
            ClosureName
        );
    end
end

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
    WriteScripts(Res);
    -- apply comments
    if Settings.Comments then
        local Info = ('-- Instances: %d | Scripts: %d\n'):format(
            #Res._INST, #Res._LUA
        );
        Res.Source = Info .. Res.Source;
    end
    -- apply logo
    if Settings.Logo then
        Res.Source = Logo .. '\n\n' .. Res.Source
    end
    return Res;
end;

return {
    Convert = Convert
}