--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.packages.React)
local Types = require(ReplicatedStorage.constants.Types)

return React.createContext({
	giftRecipient = nil :: Player?,
	crateToView = nil :: Types.Crate?,
})
