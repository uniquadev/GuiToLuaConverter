return {
    -- Generate an output folder inside the workspace with the passed name
    GetOutFolder = function(Name)
        local Out = Instance.new('Folder', workspace);
        Out.Name = Name .. os.time();
        return Out;
    end
}