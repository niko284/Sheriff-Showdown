-- Collided

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Matter = require(ReplicatedStorage.packages.Matter)

local Collided = Matter.component("Collided", {
	raycastResult = nil :: RaycastResult?,
})

return Collided
