local TextService = game:GetService("TextService")
--// REQUIRES \\--
local RbxApi = require(script.Parent.rbxapi)

--// STRUCT \\--
export type ConvertionRes = {
    Errors: {[number]: string},
    Instances: number,
    Source: string
}