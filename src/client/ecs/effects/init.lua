--!strict

local Types = require("@constants/Types")

local effects = {} :: { [string]: Types.VisualEffect<any> }

for _, effectModule in script:GetChildren() do
	local effect = require(effectModule) :: Types.VisualEffect<any>
	effects[effect.name] = effect
end

return effects
