local RbxApi = require(script.Parent.rbxapi);
local Utils = require(script.Parent.utils);
local RequireProxy = script.Parent.assets.require;
local Logo = script.Parent.assets.logo.Value;
local CollectionService = game:GetService("CollectionService");

local F_NEWINST = [[
%s["%s"] = Instance.new("%s", %s);
%s
%s
%s
]];

local F_NEWLUA = [[
local function %s()
%s
end;
task.spawn(%s);
]];

local F_NEWMOD = [=[
G2L_MODULES[%s["%s"]] = {
Closure = function()
    local script = %s["%s"];%s
end;
};
]=];

local BLACKLIST = {
    Source = true,
    Parent = true,
    ImageContent = true,
    HoverImageContent = true,
    PressedImageContent = true,
    TopImageContent = true,
    MidImageContent = true,
    BottomImageContent = true,
    VideoContent = true,
    CursorIconContent = true,
    ActivatedCursorIconContent = true,
    FallbackImageContent = true,
};

local math_round = math.round;

export type RegInstance = {
    Id: string,
    Instance: Instance,
    Parent: RegInstance?
};

export type ConvertionRes = {
    Gui: Instance,
    Settings: Settings,
    Errors: {[number]: string},
    Source: string,
    _INST: {[number]: RegInstance},
    _LUA: {[number]: RegInstance},
    _MOD: {[number]: RegInstance},
    HasTags: boolean,
    NumTags: number
};

export type Settings = {
    RegName: string,
    Comments: boolean,
    Logo: boolean
};

local function EncapsulateString(Str: string): string
    local Level = '';
    while Str:find(']' .. Level .. ']') do
        Level = Level .. '=';
    end
    return '[' .. Level .. '[' .. Str .. ']' .. Level .. ']';
end;

local function DefaultSettings(): Settings
    return {
        RegName = 'G2L',
        Comments = true,
        Logo = true
    };
end;

local function PrettifyNumber(number: number): any
    if number ~= number then
        return "0/0";
    elseif number == math.huge then
        return "math.huge";
    elseif number == -math.huge then
        return "-math.huge";
    end
    return math_round(number * 100000) / 100000;
end;

local function LoadDescendants(Res: ConvertionRes, Inst: Instance, Parent: RegInstance?)
    local Size = #Res._INST + 1;
    local RegInst = {
        Parent = Parent,
        Instance = Inst,
        Id = ('%x'):format(Size),
    };
    Res._INST[Size] = RegInst;

    if Inst:IsA('LocalScript') then
        Res._LUA[#Res._LUA + 1] = RegInst;
    elseif Inst:IsA('ModuleScript') then
        Res._MOD[#Res._MOD + 1] = RegInst;
    end;

    for _, Child in ipairs(Inst:GetChildren()) do
        LoadDescendants(Res, Child, RegInst);
    end;
end;

local function TranspileValue(RawValue: any): string
    local Value = '';
    local Type = typeof(RawValue);

    if Type == 'string' then
        Value = EncapsulateString(RawValue);
    elseif Type == 'boolean' or Type:match('^Enum') then
        Value = tostring(RawValue);
    elseif Type == 'number' then
        Value = tostring(PrettifyNumber(RawValue));
    elseif Type == 'Vector2' then
        Value = ('Vector2.new(%s, %s)'):format(
            PrettifyNumber(RawValue.X), PrettifyNumber(RawValue.Y)
        );
    elseif Type == 'Vector3' then
        Value = ('Vector3.new(%s, %s, %s)'):format(
            PrettifyNumber(RawValue.X), PrettifyNumber(RawValue.Y), PrettifyNumber(RawValue.Z)
        );
    elseif Type == 'UDim2' then
        Value = ('UDim2.new(%s, %s, %s, %s)'):format(
            PrettifyNumber(RawValue.X.Scale), PrettifyNumber(RawValue.X.Offset),
            PrettifyNumber(RawValue.Y.Scale), PrettifyNumber(RawValue.Y.Offset)
        );
    elseif Type == 'UDim' then
        Value = ('UDim.new(%s, %s)'):format(
            PrettifyNumber(RawValue.Scale), PrettifyNumber(RawValue.Offset)
        );
    elseif Type == 'Rect' then
        Value = ('Rect.new(%s, %s, %s, %s)'):format(
            PrettifyNumber(RawValue.Min.X), PrettifyNumber(RawValue.Min.Y),
            PrettifyNumber(RawValue.Max.X), PrettifyNumber(RawValue.Max.Y)
        );
    elseif Type == 'Font' then
        Value = ('Font.new(%s, %s, %s)'):format(
            EncapsulateString(RawValue.Family), tostring(RawValue.Weight), tostring(RawValue.Style)
        );
    elseif Type == 'Color3' then
        local R = math.clamp(math.round(RawValue.R * 255), 0, 255);
        local G = math.clamp(math.round(RawValue.G * 255), 0, 255);
        local B = math.clamp(math.round(RawValue.B * 255), 0, 255);
        Value = ('Color3.fromRGB(%s, %s, %s)'):format(R, G, B);
    elseif Type == 'ColorSequence' then
        local Keypoints = {};
        for _, KeyPoint: ColorSequenceKeypoint in ipairs(RawValue.Keypoints) do
            table.insert(Keypoints, ('ColorSequenceKeypoint.new(%.3f, %s)'):format(
                KeyPoint.Time, TranspileValue(KeyPoint.Value)
            ));
        end;
        Value = ('ColorSequence.new{%s}'):format(table.concat(Keypoints, ", "));
    elseif Type == 'NumberSequence' then
        local Keypoints = {};
        for _, KeyPoint: NumberSequenceKeypoint in ipairs(RawValue.Keypoints) do
            table.insert(Keypoints, ('NumberSequenceKeypoint.new(%.3f, %s)'):format(
                KeyPoint.Time, TranspileValue(KeyPoint.Value)
            ));
        end;
        Value = ('NumberSequence.new{%s}'):format(table.concat(Keypoints, ", "));
    elseif Type == 'NumberRange' then
        Value = ('NumberRange.new(%s, %s)'):format(
            PrettifyNumber(RawValue.Min), PrettifyNumber(RawValue.Max)
        );
    elseif Type == 'CFrame' then
        local Position = RawValue.Position;
        local LookVector = RawValue.LookVector;
        Value = ('CFrame.new(Vector3.new(%s, %s, %s), Vector3.new(%s, %s, %s))'):format(
            PrettifyNumber(Position.X), PrettifyNumber(Position.Y), PrettifyNumber(Position.Z),
            PrettifyNumber(LookVector.X), PrettifyNumber(LookVector.Y), PrettifyNumber(LookVector.Z)
        );
    elseif Type == 'Content' then
        local Uri = RawValue.Uri;
        if RawValue == Content.none or Uri == nil or Uri == '' then
            Value = 'Content.none';
        else
            Value = ('Content.fromUri(%s)'):format(EncapsulateString(Uri));
        end;
    elseif Type == 'Path2DControlPoint' then
        Value = ('Path2DControlPoint.new(%s, %s, %s)'):format(
            TranspileValue(RawValue.Position),
            TranspileValue(RawValue.LeftTangent),
            TranspileValue(RawValue.RightTangent)
        );
    elseif Type == 'BrickColor' then
        Value = ('BrickColor.new(%s)'):format(EncapsulateString(RawValue.Name));
    elseif Type == 'Axes' then
        local AxesArgs = {};
        if RawValue.X then table.insert(AxesArgs, 'Enum.Axis.X'); end;
        if RawValue.Y then table.insert(AxesArgs, 'Enum.Axis.Y'); end;
        if RawValue.Z then table.insert(AxesArgs, 'Enum.Axis.Z'); end;
        Value = ('Axes.new(%s)'):format(table.concat(AxesArgs, ', '));
    elseif Type == 'Faces' then
        local FaceArgs = {};
        if RawValue.Top then table.insert(FaceArgs, 'Enum.NormalId.Top'); end;
        if RawValue.Bottom then table.insert(FaceArgs, 'Enum.NormalId.Bottom'); end;
        if RawValue.Left then table.insert(FaceArgs, 'Enum.NormalId.Left'); end;
        if RawValue.Right then table.insert(FaceArgs, 'Enum.NormalId.Right'); end;
        if RawValue.Front then table.insert(FaceArgs, 'Enum.NormalId.Front'); end;
        if RawValue.Back then table.insert(FaceArgs, 'Enum.NormalId.Back'); end;
        Value = ('Faces.new(%s)'):format(table.concat(FaceArgs, ', '));
    elseif Type == 'Vector2int16' then
        Value = ('Vector2int16.new(%s, %s)'):format(
            PrettifyNumber(RawValue.X), PrettifyNumber(RawValue.Y)
        );
    elseif Type == 'Vector3int16' then
        Value = ('Vector3int16.new(%s, %s, %s)'):format(
            PrettifyNumber(RawValue.X), PrettifyNumber(RawValue.Y), PrettifyNumber(RawValue.Z)
        );
    elseif Type == 'DateTime' then
        Value = ('DateTime.fromUnixTimestampMillis(%s)'):format(
            PrettifyNumber(RawValue.UnixTimestampMillis)
        );
    end;

    return Value;
end;

local function TranspileProperties(Res: ConvertionRes, Inst: RegInstance): string
    local Properties = '';
    local Members = RbxApi.GetProperties(Inst.Instance.ClassName);

    for Member, Default: RbxApi.ValueObject in pairs(Members) do
        if BLACKLIST[Member] then
            continue;
        end;

        local CanSkip = false;
        local Integrity = pcall(function()
            CanSkip = Inst.Instance[Member] == Default.Value;
        end);

        if CanSkip or not Integrity then
            continue;
        end;

        local Transpiled = TranspileValue(Inst.Instance[Member]);
        if Transpiled == '' then
            if Utils.IsLocal() then
                Properties = Properties .. '-- ';
            else
                Properties = Properties .. ('-- [ERROR] cannot convert %s, please report to "https://github.com/uniquadev/GuiToLuaConverter/issues"\n'):format(Member);
                continue;
            end;
        end;

        Properties = Properties .. ('%s["%s"]["%s"] = %s;\n'):format(
            Res.Settings.RegName, Inst.Id, Member, Transpiled
        );
    end;

    if #Properties > 0 and Properties:sub(-1) == '\n' then
        Properties = Properties:sub(1, -2);
    end;

    return Properties;
end;

local function TranspileAttributes(Res: ConvertionRes, Inst: RegInstance): string
    local Attributes = '';
    local Found = false;

    for Attribute, RawValue in pairs(Inst.Instance:GetAttributes()) do
        local Transpiled = TranspileValue(RawValue);
        if Transpiled == '' then
            if Utils.IsLocal() then
                Attributes = Attributes .. '-- ';
            else
                continue;
            end;
        end;
        Found = true;
        Attributes = Attributes .. ('%s["%s"]:SetAttribute(%s, %s);\n'):format(
            Res.Settings.RegName, Inst.Id, EncapsulateString(Attribute), Transpiled
        );
    end;

    if Found and Res.Settings.Comments then
        Attributes = '-- Attributes\n' .. Attributes;
    end;

    return Attributes;
end;

local function TranspileTags(Res: ConvertionRes, Inst: RegInstance): string
    local Tags = '';
    local Found = false;

    for _, TagName in ipairs(CollectionService:GetTags(Inst.Instance)) do
        Res.HasTags = true;
        Found = true;
        Res.NumTags += 1;
        Tags = Tags .. ('CollectionService:AddTag(%s["%s"], %s);\n'):format(
            Res.Settings.RegName, Inst.Id, EncapsulateString(TagName)
        );
    end;

    if Found and Res.Settings.Comments then
        Tags = '-- Tags\n' .. Tags;
    end;

    return Tags;
end;

local function WriteInstances(Res: ConvertionRes)
    for _, Inst in ipairs(Res._INST) do
        local Comment = '';
        if Res.Settings.Comments then
            Comment = '-- ' .. Inst.Instance:GetFullName() .. '\n';
        end;

        local Parent = '';
        if Inst.Parent == nil then
            Parent = 'game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")';
        else
            Parent = ('%s["%s"]'):format(Res.Settings.RegName, Inst.Parent.Id);
        end;

        Res.Source = Res.Source .. Comment .. F_NEWINST:format(
            Res.Settings.RegName,
            Inst.Id,
            Inst.Instance.ClassName,
            Parent,
            TranspileProperties(Res, Inst),
            TranspileAttributes(Res, Inst),
            TranspileTags(Res, Inst)
        );

        if Inst.Instance:IsA('Path2D') then
            local Success, Points = pcall(function()
                return (Inst.Instance :: any):GetControlPoints();
            end);
            if Success and type(Points) == 'table' and #Points > 0 then
                local TranspiledPoints = {};
                for _, Point in ipairs(Points) do
                    table.insert(TranspiledPoints, TranspileValue(Point));
                end;
                Res.Source = Res.Source .. ('%s["%s"]:SetControlPoints({%s});\n'):format(
                    Res.Settings.RegName, Inst.Id, table.concat(TranspiledPoints, ', ')
                );
            end;
        end;
    end;
end;

local function WriteScripts(Res: ConvertionRes)
    if #Res._MOD > 0 then
        if Res.Settings.Comments then
            Res.Source = Res.Source .. ('-- Require G2L wrapper\n'):format(#Res._MOD);
        end;
        Res.Source = Res.Source .. RequireProxy.Source .. '\n\n';
    end;

    for _, Module in ipairs(Res._MOD) do
        Res.Source = Res.Source .. F_NEWMOD:format(
            Res.Settings.RegName, Module.Id,
            Res.Settings.RegName, Module.Id,
            Module.Instance.Source
        );
    end;

    for _, Script in ipairs(Res._LUA) do
        if Script.Instance.Disabled then
            continue;
        end;
        local ClosureName = 'C_' .. Script.Id;
        local Comment = '';
        if Res.Settings.Comments then
            Comment = '-- ' .. Script.Instance:GetFullName() .. '\n';
        end;
        local Source = ('local script = %s["%s"];\n\t'):format(
            Res.Settings.RegName, Script.Id
        ) .. Script.Instance.Source:gsub('\n', '\n\t');
        Res.Source = Res.Source .. Comment .. F_NEWLUA:format(
            ClosureName, Source, ClosureName
        );
    end;
end;

local function Convert(Gui: Instance, Settings: Settings?): ConvertionRes
    Settings = Settings or DefaultSettings();
    local Res: ConvertionRes = {
        Gui = Gui,
        Settings = Settings,
        Errors = {},
        Source = '',
        _INST = {},
        _LUA = {},
        _MOD = {},
        HasTags = false,
        NumTags = 0
    };

    Res.Source = ('local %s = {};\n\n'):format(Settings.RegName);
    LoadDescendants(Res, Gui, nil);
    WriteInstances(Res);
    WriteScripts(Res);
    Res.Source = Res.Source .. ('\nreturn %s["%s"], require;'):format(Settings.RegName, Res._INST[1].Id);

    if Res.HasTags then
        Res.Source = 'local CollectionService = game:GetService("CollectionService");\n' .. Res.Source;
    end;

    if Settings.Comments then
        local Info = ('-- Instances: %d | Scripts: %d | Modules: %d | Tags: %d\n'):format(
            #Res._INST, #Res._LUA, #Res._MOD, Res.NumTags
        );
        Res.Source = Info .. Res.Source;
    end;

    if Settings.Logo then
        Res.Source = Logo .. '\n\n' .. Res.Source;
    end;

    return Res;
end;

return {
    Convert = Convert
};
