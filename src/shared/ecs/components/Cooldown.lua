local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Matter = require(ReplicatedStorage.packages.Matter)

local Cooldown = Matter.component("Cooldown", {
	expiry = 0,
})

return Cooldown
