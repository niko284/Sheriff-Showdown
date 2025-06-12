local Matter = require("@packages/Matter")

local Health = Matter.component("Health", {
	health = 100,
	maxHealth = 100,
	regenRate = 0,
})

return Health
