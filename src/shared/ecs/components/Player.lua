local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Matter = require(ReplicatedStorage.packages.Matter)

local Player = Matter.component("Player", {
	player = nil,
})

return Player
