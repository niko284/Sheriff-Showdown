--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.packages.Net)
local Remotes = require(ReplicatedStorage.network.Remotes)
local Signal = require(ReplicatedStorage.packages.Signal)
local Types = require(ReplicatedStorage.constants.Types)

local InventoryNamespace = Remotes.Client:GetNamespace("Inventory")
local UpdateInventory = InventoryNamespace:Get("UpdateInventory") :: Net.ClientListenerEvent

local InventoryController = {
	Name = "InventoryController",
	InventoryChanged = Signal.new() :: Signal.Signal<Types.PlayerInventory>,
}

function InventoryController:OnInit()
	UpdateInventory:Connect(function(newInventory: Types.PlayerInventory)
		InventoryController.InventoryChanged:Fire(newInventory)
	end)
end

return InventoryController
