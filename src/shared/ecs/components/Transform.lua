-- Transform

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Matter = require(ReplicatedStorage.packages.Matter)

local Transform = Matter.component("Transform", {
	cframe = CFrame.new(),
	doNotReconcile = false,
})

return Transform
