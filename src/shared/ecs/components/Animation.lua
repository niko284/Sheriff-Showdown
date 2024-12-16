-- Animation

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Matter = require(ReplicatedStorage.packages.Matter)

local Animation = Matter.component("Animation", {
	animationId = 0,
	looped = false,
	speed = 1,
})

return Animation
