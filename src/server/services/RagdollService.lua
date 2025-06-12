--!strict

local NevermoreService = require("@services/NevermoreService")

local Require = NevermoreService.require

local RagdollService = {
	Name = "RagdollService",
}

function RagdollService:Ragdoll(Model: Model & { Humanoid: Humanoid })
	local ragdollBinders = NevermoreService.serviceBag:GetService(Require("RagdollBindersServer"))
	ragdollBinders.Ragdoll:Bind(Model.Humanoid)
end

function RagdollService:Unragdoll(Model: Model & { Humanoid: Humanoid })
	local ragdollBinders = NevermoreService.serviceBag:GetService(Require("RagdollBindersServer"))
	ragdollBinders.Ragdoll:Unbind(Model.Humanoid)
end

function RagdollService:IsRagdolled(Model: Model & { Humanoid: Humanoid }): boolean
	local ragdollBinders = NevermoreService.serviceBag:GetService(Require("RagdollBindersServer"))
	return ragdollBinders.Ragdoll:HasTag(Model.Humanoid)
end

return RagdollService
