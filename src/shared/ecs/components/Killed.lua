local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Matter = require(ReplicatedStorage.packages.Matter)

local Killed = Matter.component("Killed", {
	-- entityId of the entity that killed this entity
	killerEntityId = 0,
	-- when does this status expire
	expiry = 0,
})

return Killed
