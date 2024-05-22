-- Client Entity Component
-- September 9th, 2023
-- Nick

-- // Variables \\

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Packages = ReplicatedStorage.packages
local PlayerScripts = LocalPlayer.PlayerScripts
local Controllers = PlayerScripts.controllers

local Component = require(Packages.Component)
local Janitor = require(Packages.Janitor)
local NametagController = require(Controllers.NametagController)

-- // Entity \\

local EntityComponent = Component.new({
	Tag = "Entity",
	Ancestors = { workspace },
	Extensions = {},
})

-- // Functions \\

function EntityComponent:Construct()
	self.Janitor = Janitor.new()
	NametagController:CreateEntityNametag(self.Instance)
end

function EntityComponent:Stop()
	self.Janitor:Destroy()
end

return EntityComponent
