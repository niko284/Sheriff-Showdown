--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerScripts = LocalPlayer.PlayerScripts

local ClientComm = require(PlayerScripts.ClientComm)
local Net = require(ReplicatedStorage.packages.Net)
local Remotes = require(ReplicatedStorage.network.Remotes)
local Signal = require(ReplicatedStorage.packages.Signal)
local Types = require(ReplicatedStorage.constants.Types)

local InventoryNamespace = Remotes.Client:GetNamespace("Inventory")
local ItemAdded = InventoryNamespace:Get("ItemAdded") :: Net.ClientListenerEvent

local PlayerInventoryProperty = ClientComm:GetProperty("PlayerInventory")

local InventoryController = {
	Name = "InventoryController",
	InventoryChanged = Signal.new() :: Signal.Signal<Types.PlayerInventory>,
	ItemAdded = Signal.new() :: Signal.Signal<Types.Item>,
}

function InventoryController:OnInit()
	PlayerInventoryProperty:Observe(function(newInventory: Types.PlayerInventory?)
		if newInventory then
			InventoryController.InventoryChanged:Fire(newInventory)
		end
	end)
	ItemAdded:Connect(function(item: Types.Item)
		InventoryController.ItemAdded:Fire(item)
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
