local Matter = require("@packages/Matter")

local Killed = Matter.component("Killed", {
	-- entityId of the entity that killed this entity
	killerEntityId = 0,
	-- when does this status end
	expiry = 0,
})

return Killed
