local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Matter = require(ReplicatedStorage.packages.Matter)

local Despawn = Matter.component("Despawn", {})

return Despawn
