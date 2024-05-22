-- Hit FX Serde
-- August 19th, 2023
-- Nick

-- // Variables \\

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = ReplicatedStorage.constants

local Types = require(Constants.Types)

-- // Hit FX Serde \\

local HitFXMap = {
	"TargetEntity",
	"RandomSeed",
	"CFrame",
	"Target",
	"Actor",
	"Direction",
	"Origin",
}

-- // Functions \\

return {
	Serialize = function(hitFX: Types.VFXArguments)
		local serialized = {}
		for index, key in HitFXMap do
			serialized[tostring(index)] = hitFX[key]
		end
		return serialized
	end,
	Deserialize = function(serialized)
		local hitFX = {}
		for index, key in HitFXMap do
			hitFX[key] = serialized[tostring(index)]
		end
		return hitFX
	end,
}
