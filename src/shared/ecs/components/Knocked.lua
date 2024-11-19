local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.packages

local Matter = require(Packages.Matter)

local Knocked = Matter.component("Knocked", {
	strength = 0,
	direction = Vector3.zero,
	applied = false,
})

return Knocked
