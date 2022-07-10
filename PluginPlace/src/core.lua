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
local RequireProxy = script.Parent.assets.require;
local Logo = script.Parent.assets.logo.Value;

--// CONST \\--
local F_NEWINST = 
[[
%s["%s"] = Instance.new("%s", %s);
%s
%s
]]; -- %s = Settings.RegName, %s = Id, %s = ClassName, %s = Parent, %s = Properties, %s = Attributes
local F_NEWLUA =
[[
local function %s()
    %s
end;
task.spawn(%s);
]] -- %s = ClosureName, %s = ModifiedSource, %s = ClosureName
local F_NEWMOD =
[=[
G2L_MODULES[%s["%s"]] = {
    Closure = function()
        %s
    end;
};
getfenv(G2L_MODULES[%s["%s"]].Closure)["script"] = %s["%s"];
]=] -- %s = RegName, %s = Id, %s = Module.Source, %s = RegName, %s = Id, %s = RegName, %s = Id

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
    _LUA: {RegInstance}, -- hold local scripts
    _MOD: {RegInstance}  -- hold module scripts
}

export type Settings = {
    RegName: string,
    Comments: boolean,
    Logo: boolean
}

--// UTIL \\--
local function EncapsulateString(Str:string)
    local Level = '';
    while true do
        if Str:find(']' .. Level .. ']') then
            Level = Level .. '=';
        else
            break;
        end
    end
    return '['..Level..'[' .. Str .. ']'..Level..']';
end;

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
    elseif Inst:IsA('ModuleScript') then
        Res._MOD[#Res._MOD+1] = RegInst;
    end;
    -- loop children
    for Idx, Child in next, Inst:GetChildren() do
        LoadDescendants(Res, Child, RegInst) -- recursive time 8)
    end;
end;

-- transpile property to lua
local function TranspileValue(RawValue:any)
    local Value = '';
    local Type = typeof(RawValue);
    if Type == 'string' then
        Value = EncapsulateString(RawValue);
    elseif Type == 'number' or Type == 'boolean' or Type:match('^Enum') then
        Value = tostring(RawValue);
    -- %.3f format might be better
    elseif Type == 'Vector2' then
        Value = ('Vector2.new(%s, %s)'):format(
            RawValue.X, RawValue.Y
        );
    elseif Type == 'Vector3' then
        Value = ('Vector3.new(%s, %s, %s)'):format(
            RawValue.X, RawValue.Y, RawValue.Z
        );
    elseif Type == 'UDim2' then
        Value = ('UDim2.new(%s, %s, %s, %s)'):format(
            RawValue.X.Scale, RawValue.X.Offset,
            RawValue.Y.Scale, RawValue.Y.Offset
        );
    elseif Type == 'UDim' then
        Value = ('UDim.new(%s, %s)'):format(
            RawValue.Scale, RawValue.Offset
        );
    elseif Type == 'Rect' then
        Value = ('Rect.new(%s, %s, %s, %s)'):format(
            RawValue.Min.X, RawValue.Min.Y,
            RawValue.Max.X, RawValue.Max.Y
        );
    elseif Type == 'Color3' then
        -- convert rgb float value to decimal
        local R, G, B = math.ceil(RawValue.R * 255), math.ceil(RawValue.G * 255), math.ceil(RawValue.B * 255);
        Value = ('Color3.fromRGB(%s, %s, %s)'):format(
            R, G, B
        );
    end
    return Value;
end

local function TranspileProperties(Res:ConvertionRes, Inst:RegInstance) : string
    local Properties = '';
    local Members = RbxApi.GetProperties(Inst.Instance.ClassName);
    for Member, Default:RbxApi.ValueObject in pairs(Members) do
        -- special case skip
        if BLACKLIST[Member] then
            continue;         
        -- default property case
        else
            local CanSkip = false;
            -- skip if default value is set
            local Integrity = pcall(function()
                CanSkip = Inst.Instance[Member] == Default.Value;
            end);
            if CanSkip or not Integrity then
                continue;
            end
            -- transpile value
            local Transpiled = TranspileValue(Inst.Instance[Member]);
            -- if transpiled value is not resolved
            if Transpiled == '' then 
                if Utils.IsLocal() then
                    Properties = Properties .. '-- '; -- comment property to debug it
                else
                    continue; -- skip property
                end;
            end
            -- append transpiled property to properties
            Properties =  Properties .. ('%s["%s"]["%s"] = %s;\n'):format(
                Res.Settings.RegName, Inst.Id,
                Member, Transpiled
            );
        end;
    end;
    return Properties;
end;

local function TranspileAttributes(Res:ConvertionRes, Inst:RegInstance) : string
    local Attributes = '';
    local Found = false;
    -- loop attributes and transpile them
    for Attribute, RawValue in next, Inst.Instance:GetAttributes() do
        local Transpiled = TranspileValue(RawValue);
        -- if transpiled value is not resolved
        if Transpiled == '' then 
            if Utils.IsLocal() then
                Attributes = Attributes .. '-- '; -- comment property to debug it
            else
                continue; -- skip property
            end;
        end;
        Found = true;
        -- append transpiled attribute to attributes
        Attributes = Attributes .. ('%s["%s"]:SetAttribute(%s, %s);\n'):format(
            Res.Settings.RegName, Inst.Id,
            EncapsulateString(Attribute), Transpiled
        );
    end;
    -- apply comment if attributes found
    if Found and Res.Settings.Comments then
        Attributes =  '-- Attributes\n' .. Attributes;
    end;
    return Attributes;
end

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
            TranspileProperties(Res, Inst), TranspileAttributes(Res, Inst)
        );
    end
end;

local function WriteScripts(Res:ConvertionRes)
    -- write require proxy before loading all modules
    if #Res._MOD > 0 then
        if Res.Settings.Comments then
            Res.Source = Res.Source .. ('-- Require G2L wrapper\n'):format(#Res._MOD);
        end;
        Res.Source = Res.Source .. RequireProxy.Source .. '\n\n';
    end;
    -- register all modules state in the G2L_MODULES
    for _, Module in next, Res._MOD do
        Res.Source = Res.Source .. F_NEWMOD:format(
            Res.Settings.RegName, Module.Id,
            Module.Instance.Source,
            Res.Settings.RegName, Module.Id,
            Res.Settings.RegName, Module.Id
        );
    end
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
        -- fix tabulation and apply script variable in the env
        local Source = ('local script = %s["%s"];\n'):format(
            Res.Settings.RegName, Script.Id
        ) .. Script.Instance.Source:gsub('\n', '\n\t');
        -- write
        Res.Source = Res.Source .. Comment .. F_NEWLUA:format(
            ClosureName, Source,
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
        _LUA = {},
		_MOD = {}
    };
    Res.Source = ('local %s = {};\n'):format(Settings.RegName);
    LoadDescendants(Res, Gui, nil);
    WriteInstances(Res);
    WriteScripts(Res);
    -- apply comments
    if Settings.Comments then
        local Info = ('-- Instances: %d | Scripts: %d | Modules: %d\n'):format(
            #Res._INST, #Res._LUA, #Res._MOD
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