-- Ragdoll Service
-- March 11th, 2023
-- Nick

-- // Variables \\

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Constants = ReplicatedStorage.constants
local Services = ServerScriptService.services

local NevermoreService = require(Services.NevermoreService)
local Types = require(Constants.Types)

-- // Service \\

local RagdollService = {
	Name = "RagdollService",
}

-- // Functions \\

function RagdollService:Start()
	NevermoreService:GetPackage("RagdollService")
end

function RagdollService:Ragdoll(Entity: Types.Entity)
	local ragdollBinders = NevermoreService:GetPackage("RagdollBindersServer")
	ragdollBinders.Ragdoll:Bind(Entity.Humanoid)
end

function RagdollService:Unragdoll(Entity: Types.Entity)
	local ragdollBinders = NevermoreService:GetPackage("RagdollBindersServer")
	ragdollBinders.Ragdoll:Unbind(Entity.Humanoid)
end

return RagdollService
