--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.packages.React)

return React.createContext({
	giftRecipient = nil :: Player?,
})
