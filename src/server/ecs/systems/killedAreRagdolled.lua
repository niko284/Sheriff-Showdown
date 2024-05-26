local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Components = require(ReplicatedStorage.ecs.components)
local Matter = require(ReplicatedStorage.packages.Matter)
local MatterTypes = require(ReplicatedStorage.ecs.MatterTypes)

type KilledRecord = MatterTypes.WorldChangeRecord<Components.Killed>

local function killsAreProcessed(world: Matter.World)
	for eid, killedRecord: KilledRecord in world:queryChanged(Components.Killed) do
		if killedRecord.new then -- killed entities are ragdolled
			local ragdolled = world:get(eid, Components.Ragdolled)
			if ragdolled == nil then
				world:insert(eid, Components.Ragdolled())
			end
		else -- revived/un-killed entities are unragdolled
			local ragdolled = world:get(eid, Components.Ragdolled)
			if ragdolled ~= nil then
				world:remove(eid, Components.Ragdolled)
			end
		end
	end
end

return killsAreProcessed
