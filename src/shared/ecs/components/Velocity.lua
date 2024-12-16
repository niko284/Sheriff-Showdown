-- Velocity

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Matter = require(ReplicatedStorage.packages.Matter)

local Velocity = Matter.component("Velocity", {
	velocity = Vector3.new(0, 0, 0),
})

return Velocity
