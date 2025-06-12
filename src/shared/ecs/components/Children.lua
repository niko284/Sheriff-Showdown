local Matter = require("@packages/Matter")

local Children = Matter.component("Children", {
	children = {}, -- list of entity ids that are owned by this entity
})

return Children
