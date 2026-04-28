--!strict

local RagdollService = {
	Name = "RagdollService",
}

function RagdollService:Ragdoll(Model: Model & { Humanoid: Humanoid }) end

function RagdollService:Unragdoll(Model: Model & { Humanoid: Humanoid }) end

function RagdollService:IsRagdolled(Model: Model & { Humanoid: Humanoid }): boolean
	return false
end

return RagdollService
