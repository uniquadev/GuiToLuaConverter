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

--// STRUCT \\--
export type ClassObject = {
    Name: string,
    Members: {[string]: any}, -- Property1: DefaultValue
    Superclass: ClassObject
}

--// SERIALIZE \\--
for ClassName, ClassObj:ClassObject in pairs(Dump) do
    ClassObj.Name = ClassName;
    -- invert index to value
    local Members = {};
    for _, Member in pairs(ClassObj.Members) do
        Members[Member] = {}; -- since we can't set nil as default;
    end
    ClassObj.Members = Members; -- should force gc of the dump members
    -- register class obj
    ROBLOX_REG[ClassName] = ClassObj;
end;

--// CORE \\--

-- Load all default value of the passed Class inside ROBLOX_REG
local function LoadDefaultValues(ClassName:string) : nil
    -- check if already loaded
    if DUMMIES[ClassName] or not ROBLOX_REG[ClassName] then
        return;
    end
    -- make dummy
    local Dummy;
    pcall(function()
        Dummy = Instance.new(ClassName);
    end);
    -- store dummy
    DUMMIES[ClassName] = Dummy or true;
    -- check dummy integrity
	if not Dummy then
		return;
	end
    -- store default values
    local ClassObj = ROBLOX_REG[ClassName];
    for Member in pairs(ClassObj.Members) do
        ClassObj.Members[Member] = Dummy[Member];
    end;
end
local function GetProperties(ClassName:string) : {[string]: any} | nil
    -- check if registred
    local ClassObj = ROBLOX_REG[ClassName];
    if not ClassObj then
        return;
    end
    local Members = {}
    -- Load superclass
    LoadDefaultValues(ClassObj.Superclass);
    local SuperMembers = GetProperties(ClassObj.Superclass);
    -- check if found
    if SuperMembers then
        for Member, DefaultValue in pairs(SuperMembers) do
            Members[Member] = DefaultValue;
        end;
    end;
    -- Load class
    LoadDefaultValues(ClassName);
    for Member, DefaultValue in pairs(ClassObj.Members) do
        Members[Member] = DefaultValue;
    end
    return Members;
end

local function GetDummy(ClassName:string) : Instance
    return DUMMIES[ClassName];
end

return {
    GetProperties = GetProperties;
    GetDummy = GetDummy;
}