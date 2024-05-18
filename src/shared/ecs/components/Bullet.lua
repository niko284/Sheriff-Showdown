-- Bullet

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Matter = require(ReplicatedStorage.packages.Matter)

local Bullet = Matter.component("Bullet", {
	currentCFrame = CFrame.new(),
	filter = {},
	gunId = nil,
})

return Bullet
