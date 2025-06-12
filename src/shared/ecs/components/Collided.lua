-- Collided

local Matter = require("@packages/Matter")

local Collided = Matter.component("Collided", {
	raycastResult = nil :: RaycastResult?,
})

return Collided
