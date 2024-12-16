local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Matter = require(ReplicatedStorage.packages.Matter)

local MerryGoRound = Matter.component("MerryGoRound", {
	targetAngularVelocity = 0,
	currentAngularVelocity = 0,
	angularAcceleration = 0.1,
	maxAngularVelocity = 12,
})

return MerryGoRound
