--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.packages.React)
local Types = require(ReplicatedStorage.constants.Types)

return React.createContext({
	currentTrade = nil :: Types.Trade?,
	showTradeSideButton = false :: boolean, -- should the trade side button be shown?
})
