--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local Services = ServerScriptService.services

local NevermoreService = require(Services.NevermoreService)

local RagdollService = {
	Name = "RagdollService",
}

function RagdollService:OnStart()
	NevermoreService:GetPackage("RagdollService")
end

function RagdollService:Ragdoll(Model: Model & { Humanoid: Humanoid })
	local ragdollBinders = NevermoreService:GetPackage("RagdollBindersServer")
	ragdollBinders.Ragdoll:Bind(Model.Humanoid)
end

function RagdollService:Unragdoll(Model: Model & { Humanoid: Humanoid })
	local ragdollBinders = NevermoreService:GetPackage("RagdollBindersServer")
	ragdollBinders.Ragdoll:Unbind(Model.Humanoid)
end

function RagdollService:IsRagdolled(Model: Model & { Humanoid: Humanoid }): boolean
	local ragdollBinders = NevermoreService:GetPackage("RagdollBindersServer")
	return ragdollBinders.Ragdoll:HasTag(Model.Humanoid)
end

return RagdollService
