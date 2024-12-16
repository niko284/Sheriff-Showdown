local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.packages

local Matter = require(Packages.Matter)

local Health = Matter.component("Health", {
	health = 100,
	maxHealth = 100,
	regenRate = 0,
})

return Health
