--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerScripts = LocalPlayer.PlayerScripts
local Controllers = PlayerScripts.controllers

local InventoryContext = require(ReplicatedStorage.react.contexts.InventoryContext)
local InventoryController = require(Controllers.InventoryController)
local React = require(ReplicatedStorage.packages.React)
local Types = require(ReplicatedStorage.constants.Types)

local useState = React.useState
local useEffect = React.useEffect
local e = React.createElement

local function InventoryProvider(props)
	local inventory, setInventory = useState(nil :: Types.PlayerInventory?)

	useEffect(function()
		if inventory == nil then
			local replicatedInventory = InventoryController:GetReplicatedInventory()
			if replicatedInventory then
				setInventory(replicatedInventory)
			end
		end
		local connection = InventoryController.InventoryChanged:Connect(function(newInventory)
			setInventory(newInventory)
		end)
		return function()
			connection:Disconnect()
		end
	end, {inventory})

	return e(InventoryContext.Provider, {
		value = inventory,
	}, props.children)
end

return InventoryProvider
