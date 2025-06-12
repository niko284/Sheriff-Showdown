local Matter = require("@packages/Matter")

local Knocked = Matter.component("Knocked", {
	strength = 0,
	direction = Vector3.zero,
	applied = false,
})

return Knocked
