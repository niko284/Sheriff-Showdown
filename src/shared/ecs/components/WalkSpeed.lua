local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Matter = require(ReplicatedStorage.packages.Matter)

local WalkSpeed = Matter.component("WalkSpeed", {
	speed = 16,
	modifier = 1,
})

return WalkSpeed
