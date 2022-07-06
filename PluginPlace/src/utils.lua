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
        local LocalScript = Instance.new('LocalScript', Out);
        LocalScript.Disabled = true;
        LocalScript.Source = Res.Source;
        -- TODO split support
        return Out;
    end;
}

return Utils;