-- !strict

-- Effects
-- May 12th, 2024
-- Nick

-- // Variables \\

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = ReplicatedStorage.constants

local Types = require(Constants.Types)

local Effects = {} :: { [string]: Types.Effect }

-- // Effects \\

for _, effect in script:GetChildren() do
	local effectModule = require(effect) :: Types.Effect
	Effects[effectModule.Name] = effectModule
end

return Effects
