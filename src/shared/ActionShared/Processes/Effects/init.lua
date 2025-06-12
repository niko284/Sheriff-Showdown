-- !strict

local Types = require("@constants/Types")

local Effects = {} :: { [string]: Types.Effect }

for _, effect in script:GetChildren() do
	local effectModule = require(effect) :: Types.Effect
	Effects[effectModule.Name] = effectModule
end

return Effects
