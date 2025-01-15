--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Matter = require(ReplicatedStorage.packages.Matter)
local React = require(ReplicatedStorage.packages.React)

return React.createContext({
	world = nil :: Matter.World?,
})
