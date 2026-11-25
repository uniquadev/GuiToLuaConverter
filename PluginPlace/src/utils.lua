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
        local Dummy = Instance.new("LocalScript");
        local Success = pcall(function()
            -- UpdateSourceAsync is only reliable on parented scripts
            Dummy.Name = "Test";
            Dummy.Parent = game:GetService("StarterPack");
            game:GetService("ScriptEditorService"):UpdateSourceAsync(Dummy, function()
                return "print('Hello World');";
            end);
        end);
        Dummy:Destroy();
        return Success;
    end,
    -- Write parse res Source in a LocalScript. UpdateSourceAsync isn't affected by the
    -- 200k characters limit of Script.Source, so there is no need to split the output
    WriteConvertionRes = function(Res:G2L.ConvertionRes) : Folder
        -- carriage returns can make UpdateSourceAsync fail
        local Source = Res.Source:gsub('\r\n?', '\n');
        local Integrity, ScriptOrMsg = pcall(function()
            local LocalScript = Instance.new('LocalScript', game:GetService("StarterPack"));
            LocalScript.Name = `{Res.Gui.Name}_{Res.Gui:GetDebugId(0)}`;
            game:GetService("ScriptEditorService"):UpdateSourceAsync(LocalScript, function()
                return Source
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
