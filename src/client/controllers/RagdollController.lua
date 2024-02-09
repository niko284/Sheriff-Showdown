-- Ragdoll Controller
-- August 17th, 2022
-- Nick

-- // Variables \\

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer
local Constants = ReplicatedStorage.constants
local PlayerScripts = Player.PlayerScripts
local Controllers = PlayerScripts.controllers

local NevermoreController = require(Controllers.NevermoreController)
local Types = require(Constants.Types)

-- // Controller \\

local RagdollController = { Name = "RagdollController" }

-- // Functions \\

function RagdollController:Start()
	NevermoreController:GetPackage("RagdollServiceClient")
	NevermoreController:GetPackage("RagdollBindersClient")
	NevermoreController:GetPackage("CameraStackService")
	NevermoreController:GetPackage("DefaultCamera")
end

function RagdollController:Ragdoll(Entity: Types.Entity)
	local ragdollBinders = NevermoreController:GetPackage("RagdollBindersClient")
	ragdollBinders.Ragdoll:Bind(Entity.Humanoid)
end

function RagdollController:Unragdoll(Entity: Types.Entity)
	local ragdollBinders = NevermoreController:GetPackage("RagdollBindersClient")
	ragdollBinders.Ragdoll:Unbind(Entity.Humanoid)
end

return RagdollController
