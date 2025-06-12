local Matter = require("@packages/Matter")

local Cooldown = Matter.component("Cooldown", {
	expiry = 0,
})

return Cooldown
