local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Components = require(ReplicatedStorage.ecs.components)
local Matter = require(ReplicatedStorage.packages.Matter)
local MatterTypes = require(ReplicatedStorage.ecs.MatterTypes)
local RagdollService = require(ServerScriptService.services.RagdollService)

type RagdolledRecord = MatterTypes.WorldChangeRecord<Components.Ragdolled>

local function ragdollsAreApplied(world: Matter.World)
	-- ragdolls are applied to entities with a Renderable and Ragdolled component
	for _eid, renderable: Components.Renderable, _ragdolled: Components.Ragdolled in
		world:query(Components.Renderable, Components.Ragdolled)
	do
		local humanoid = renderable.instance:FindFirstChildOfClass("Humanoid")
		if humanoid and RagdollService:IsRagdolled(renderable.instance :: any) == false then
			RagdollService:Ragdoll(renderable.instance :: any)
		end
	end

	-- ragdolls are removed from entities without a Ragdolled component
	for eid, ragdolledRecord: RagdolledRecord in world:queryChanged(Components.Ragdolled) do
		if ragdolledRecord.new == nil then -- the ragdolled component was removed from an entity
			local renderable = world:get(eid, Components.Renderable)
			if renderable then
				local humanoid = renderable.instance:FindFirstChildOfClass("Humanoid")
				if humanoid then
					RagdollService:Unragdoll(renderable.instance :: any)
				end
			end
		end
	end
end

return ragdollsAreApplied
