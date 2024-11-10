--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Matter = require(ReplicatedStorage.packages.Matter)

local Parent = Matter.component("Parent", {
	id = nil, -- parent entity id.
})

return Parent
