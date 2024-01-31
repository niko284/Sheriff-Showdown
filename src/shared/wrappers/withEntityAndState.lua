--!strict

-- With Entity and State Wrapper
-- May 6th, 2023
-- Nick

-- // Variables \\

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ActionShared = ReplicatedStorage.ActionShared

local EntityModule = require(ActionShared.Entity)

local function withPlayerEntity(fn)
	return function(player: Player, ...: any): ()
		if not player.Character then
			return false
		end
		local entity, entityState = EntityModule.GetEntityAndState(player.Character)
		if entity and entityState then
			return fn(player, entity, entityState, ...)
		else
			return false
		end
	end
end

return withPlayerEntity
