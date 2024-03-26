-- Resource Controller
-- February 26th, 2022
-- Nick

-- // Variables \\

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerScripts = LocalPlayer.PlayerScripts
local Packages = ReplicatedStorage.packages
local Slices = PlayerScripts.rodux.slices

local ClientComm = require(PlayerScripts.ClientComm)
local ResourcesSlice = require(Slices.ResourcesSlice)
local Signal = require(Packages.Signal)

local PlayerResourcesProperty = ClientComm:GetProperty("PlayerResources")

-- // Controller Variables \\

local ResourceController = {
	Name = "ResourceController",
	ResourceChanged = Signal.new(),
}

-- // Functions \\

function ResourceController:Init()
	self.Store = require(PlayerScripts.rodux.Store)
	PlayerResourcesProperty:Observe(function(partialResourceState)
		self.Store:dispatch(ResourcesSlice.actions.SetResources(partialResourceState))
	end)
end

function ResourceController:GetResources()
	if not self.Store then
		return {}
	end
	local state = self.Store:getState()
	return state.Resources
end

function ResourceController:GetResource(ResourceName: string): any?
	if not self.Store then
		return nil
	end
	local state = self.Store:getState()
	return state.Resources[ResourceName]
end

return ResourceController
