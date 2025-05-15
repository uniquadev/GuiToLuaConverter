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
    GetOutFolder = function(Name) : Folder
        local Out = Instance.new('Folder', game:GetService('StarterPack'));
        Out.Name = Name .. os.time();
        return Out;
    end,
    -- Write parse res Source in a disabled LocalScript, and split it in case roblox
    -- limit the write to the buffer
    WriteConvertionRes = function(Res:G2L.ConvertionRes) : Folder
        local Out = Utils.GetOutFolder(Res.Gui.Name);
        local Integrity = pcall(function()
            local LocalScript = Instance.new('LocalScript', Out);
            LocalScript.Name = "ConvertedScript";
            game:GetService("ScriptEditorService"):UpdateSourceAsync(LocalScript, function()
                return Res.Source
            end);
        end);
        if not Integrity then
            warn("Can't write the converted script in the LocalScript.");
        end
        return Out;
    end;
}

return Utils;
