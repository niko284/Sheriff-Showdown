local Components = require("@ecs/components")
local Effects = require("@client/ecs/effects")
local Matter = require("@packages/Matter")
local MatterReplication = require("@packages/MatterReplication")
local MatterTypes = require("@ecs/MatterTypes")

local KillEffect = Effects.KillEffect

type KilledRecord = MatterTypes.WorldChangeRecord<Components.Killed>

local function killEffectsAreShown(world: Matter.World)
	for eid, killedRecord: KilledRecord in world:queryChanged(Components.Killed) do
		print(killedRecord)
		if killedRecord.new then
			local serverEntity: MatterReplication.ServerEntityData = world:get(eid, MatterReplication.ServerEntity)
			KillEffect.visualize(world, {
				killerServerEntityId = killedRecord.new.killerEntityId,
				killedServerEntityId = serverEntity.id,
			})
		end
	end
end

return killEffectsAreShown
