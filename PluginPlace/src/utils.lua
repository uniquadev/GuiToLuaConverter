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
            game:GetService("ScriptEditorService"):UpdateSourceAsync(Dummy, function()
                return "print('Hello World');";
            end);
            Dummy.Name = "Test";
            Dummy.Parent = game:GetService("StarterPack");
            Dummy:Destroy();
        end);
        return Success;
    end,
    -- Write parse res Source in a disabled LocalScript, and split it in case roblox
    -- limit the write to the buffer
    WriteConvertionRes = function(Res:G2L.ConvertionRes) : Folder
        local Integrity, ScriptOrMsg = pcall(function()
            local LocalScript = Instance.new('LocalScript', game:GetService("StarterPack"));
            LocalScript.Name = `{Res.Gui.Name}_{Res.Gui:GetDebugId(0)}`;
            game:GetService("ScriptEditorService"):UpdateSourceAsync(LocalScript, function()
                return Res.Source
            end);
            return LocalScript
        end);
        if not Integrity then
            error(`Can't write the converted script in the LocalScript.\n{ScriptOrMsg}`);
        end
        return ScriptOrMsg
    end;
}

return Utils;
