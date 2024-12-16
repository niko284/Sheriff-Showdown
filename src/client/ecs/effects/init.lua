--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.constants.Types)

local effects = {} :: { [string]: Types.VisualEffect<any> }

for _, effectModule in script:GetChildren() do
	local effect = require(effectModule) :: Types.VisualEffect<any>
	effects[effect.name] = effect
end

return effects
