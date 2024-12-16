--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local PlayerScripts = LocalPlayer.PlayerScripts

local Signal = require(ReplicatedStorage.packages.Signal)
local Types = require(ReplicatedStorage.constants.Types)
local ClientComm = require(PlayerScripts.ClientComm)

local PlayerResourcesProperty = ClientComm:GetProperty("PlayerResources")

local ResourceController = {
    Name = "ResourceController",
    ResourcesChanged = Signal.new() :: Signal.Signal<Types.PlayerResources>,
}

function ResourceController:OnInit()
    PlayerResourcesProperty:Observe(function(playerResources: Types.PlayerResources)
        ResourceController.ResourcesChanged:Fire(playerResources)
    end)
end

function ResourceController:GetReplicatedResources()
    return PlayerResourcesProperty:Get()
end

return ResourceController