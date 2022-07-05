--[[
                    $$\                                                                       
                    \__|                                                                      
 $$$$$$\   $$$$$$\  $$\  $$$$$$$\        $$$$$$\   $$$$$$\  $$$$$$\$$$$\   $$$$$$\   $$$$$$\  
$$  __$$\ $$  __$$\ $$ |$$  _____|      $$  __$$\  \____$$\ $$  _$$  _$$\ $$  __$$\ $$  __$$\ 
$$$$$$$$ |$$ /  $$ |$$ |$$ /            $$ /  $$ | $$$$$$$ |$$ / $$ / $$ |$$$$$$$$ |$$ |  \__|
$$   ____|$$ |  $$ |$$ |$$ |            $$ |  $$ |$$  __$$ |$$ | $$ | $$ |$$   ____|$$ |      
\$$$$$$$\ $$$$$$$  |$$ |\$$$$$$$\       \$$$$$$$ |\$$$$$$$ |$$ | $$ | $$ |\$$$$$$$\ $$ |      
 \_______|$$  ____/ \__| \_______|       \____$$ | \_______|\__| \__| \__| \_______|\__|      
          $$ |                          $$\   $$ |                                            
          $$ |                          \$$$$$$  |                                            
          \__|                           \______/                                             
]]

--// REQUIRES \\--
local Dump = require(script.Parent:WaitForChild("dump")) -- dump.json generated with the RobloxDumper

--// GLOBALS \\--

-- _Hold all deserialized classes of the dump._
local ROBLOX_REG : {[string]: ClassObject} = {};
-- _Contain all dummy instances used to check default values._
local DUMMIES : {[string]: Instance} = {};
local CACHE : {[string]: PropertiesRes} = {}; -- cache results to avoid loading members & defaults every time

--// STRUCT \\--
export type ValueObject = {Value: any};
export type ClassObject = {
    Name: string,
    Members: {[number]: string}, -- Property1: DefaultValue
    Superclass: ClassObject
}
export type PropertiesRes = {[string]: ValueObject} | nil

--// SERIALIZE \\--
for ClassName, ClassObj:ClassObject in pairs(Dump) do
    ClassObj.Name = ClassName;
    -- register class obj
    ROBLOX_REG[ClassName] = ClassObj;
end;

--// CORE \\--

-- Load default values of the passed members dictionary
local function LoadDefaultValues(ClassName:string, Members:PropertiesRes) : nil
    -- make dummy
    local Dummy;
    pcall(function()
        Dummy = DUMMIES[ClassName] or Instance.new(ClassName);
    end);
    -- store dummy
    DUMMIES[ClassName] = Dummy or false;
    -- check dummy integrity
	if not Dummy then
		return;
	end
    -- store default values
    for Member, Default in pairs(Members) do
        pcall(function() -- errors like 'The current identity (5) cannot access...' can occur
			Default.Value = Dummy[Member];
		end);
    end;
end
-- Return a table containing Members as index and member's DefaultValue as value
local function GetProperties(ClassName:string) : PropertiesRes
    -- check cache
    if CACHE[ClassName] then
        return CACHE[ClassName];
    end
    -- check if registred
    local ClassObj = ROBLOX_REG[ClassName];
    if not ClassObj then
        return;
    end
    local Members : PropertiesRes = {}
    -- Load superclass
    local SuperMembers = GetProperties(ClassObj.Superclass);
    -- check if found
    if SuperMembers then
        for Member, DefaultValue in pairs(SuperMembers) do
            Members[Member] = DefaultValue;
        end;
    end;
    -- Load class
    for _, Member in pairs(ClassObj.Members) do
        Members[Member] = {
            Value = nil
        };
    end
    LoadDefaultValues(ClassName, Members);
    CACHE[ClassName] = Members;
    return Members;
end

local function GetDummy(ClassName:string) : Instance
    return DUMMIES[ClassName];
end

return {
    GetProperties = GetProperties;
    GetDummy = GetDummy;
}