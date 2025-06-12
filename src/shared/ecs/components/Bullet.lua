-- Bullet

local Matter = require("@packages/Matter")

local Bullet = Matter.component("Bullet", {
	filter = {},
	gunId = nil,
})

return Bullet
