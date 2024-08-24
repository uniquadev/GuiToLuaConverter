--// REQUIRE \\--
local G2L;
if false then -- fake block, just load the G2L.ConvertionRes for typechecking
    G2L = require(script.Parent.core);
end

local Utils;
Utils = {
    -- Detect if the plugin is running locally
	IsLocal = function() : boolean
		return string.find(plugin.Name, ".rbxm") or string.find(plugin.Name, ".lua");
	end,
    -- Check if plugin has write access to scripts
    HasWriteAccess = function() : boolean
        local Success = pcall(function()
            local Dummy = Instance.new("LocalScript");
            Dummy.Source = "print('Hello World');";
            Dummy.Name = "Test";
            Dummy.Parent = game:GetService("StarterPack");
            Dummy:Destroy();
        end);
        return Success;
    end,
    -- Generate an output folder inside the workspace with the passed name
    GetOutFolder = function(ins: Instance) : Folder
        local Out = Instance.new('Folder', game:GetService('StarterPack'));
        Out.Name = ins.Name .. ins:GetDebugId();
        return Out;
    end,
    -- Write parse res Source in a disabled LocalScript, and split it in case roblox
    -- limit the write to the buffer
    WriteConvertionRes = function(Res:G2L.ConvertionRes) : Folder
        local Out = Utils.GetOutFolder(Res.Gui);
        -- split support
        local Parts = {};
        local Idx = 0;
        local SplitSize = 100000;
        while true do
            local Part = Res.Source:sub((SplitSize * Idx) + 1, SplitSize*(Idx+1));
            if Part == '' then
                break;
            end;
            table.insert(Parts, Part);
            Idx += 1;
        end;
        local Integrity, Error = pcall(function()
            for i, Source in next, Parts do
                local LocalScript = Instance.new('LocalScript', Out);
                LocalScript.Name = tostring(i);
                LocalScript.Disabled = true;
                LocalScript.Source = Source;
            end
        end);
        if not Integrity then
            warn(`Can't write the converted script in the LocalScript, {Error}.`);
        end
        return Out;
    end;
}

return Utils;
