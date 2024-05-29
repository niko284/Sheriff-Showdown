--!strict

local Players = game:GetService("Players")

local Player = Players.LocalPlayer
local PlayerScripts = Player.PlayerScripts
local Controllers = PlayerScripts.controllers

local NevermoreController = require(Controllers.NevermoreController)

local RagdollController = { Name = "RagdollController" }

function RagdollController:OnStart()
	NevermoreController:GetPackage("RagdollServiceClient")
end

return RagdollController
