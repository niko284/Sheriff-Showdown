local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Components = require(ReplicatedStorage.ecs.components)
local Matter = require(ReplicatedStorage.packages.Matter)
local MatterTypes = require(ReplicatedStorage.ecs.MatterTypes)

type KilledRecord = MatterTypes.WorldChangeRecord<Components.Killed>

local function killsAreProcessed(world: Matter.World)
	-- killed components are removed when they expire
	for eid, killed: Components.Killed in world:query(Components.Killed) do
		local renderable = world:get(eid, Components.Renderable) :: Components.Renderable?
		if os.time() >= killed.expiry and renderable then
			local plrFromRenderable = Players:GetPlayerFromCharacter(renderable.instance)
			if plrFromRenderable then
				task.spawn(plrFromRenderable.LoadCharacter, plrFromRenderable)
			else
				renderable.instance:Destroy() -- destroy the entity if it's not a player (e.g. a target dummy)
			end
		end
	end

	-- killed entities are ragdolled
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
