--!strict

local jecs = require("@packages/jecs")

local Components = require("@ecs/components")
local RagdollService = require("@services/RagdollService")

local function ragdollsAreApplied(world: jecs.World)
	for _eid, renderable, _ragdolled in world:query(Components.Renderable, Components.Ragdolled) do
		local humanoid = renderable.instance:FindFirstChildOfClass("Humanoid")
		if humanoid and not RagdollService:IsRagdolled(renderable.instance :: any) then
			RagdollService:Ragdoll(renderable.instance :: any)
		end
	end
	-- Unragdoll on Ragdolled removal is handled by the OnRemove observer in server/ecs/observers.lua.
end

return ragdollsAreApplied
