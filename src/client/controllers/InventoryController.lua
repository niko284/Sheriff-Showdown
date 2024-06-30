--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerScripts = LocalPlayer.PlayerScripts

local ClientComm = require(PlayerScripts.ClientComm)
local Signal = require(ReplicatedStorage.packages.Signal)
local Types = require(ReplicatedStorage.constants.Types)

local PlayerInventoryProperty = ClientComm:GetProperty("PlayerInventory")

local InventoryController = {
	Name = "InventoryController",
	InventoryChanged = Signal.new() :: Signal.Signal<Types.PlayerInventory>,
}

function InventoryController:OnInit()
	PlayerInventoryProperty:Observe(function(newInventory: Types.PlayerInventory?)
		if newInventory then
			InventoryController.InventoryChanged:Fire(newInventory)
		end
	end)
end

function InventoryController:GetReplicatedInventory()
	return PlayerInventoryProperty:Get()
end

function InventoryController:ObserveInventoryChanged(callback: (Types.PlayerInventory) -> ())
	local inventory = PlayerInventoryProperty:Get()
	if inventory then
		callback(inventory)
	end
	return InventoryController.InventoryChanged:Connect(callback)
end

return InventoryController
