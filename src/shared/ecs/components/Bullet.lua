-- Bullet

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Matter = require(ReplicatedStorage.packages.Matter)

local Bullet = Matter.component("Bullet", {
	filter = {},
	gunId = nil,
})

return Bullet
