--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.packages.React)
local Types = require(ReplicatedStorage.constants.Types)

return React.createContext({
	currentTrade = nil :: Types.Trade?,
	isInInventory = false :: boolean, -- is the player in the inventory screen to trade? this will switch the inventory's behavior
	showTradeSideButton = false :: boolean, -- should the trade side button be shown?
})
