local Matter = require("@packages/Matter")

local WalkSpeed = Matter.component("WalkSpeed", {
	speed = 16,
	modifier = 1,
})

return WalkSpeed
