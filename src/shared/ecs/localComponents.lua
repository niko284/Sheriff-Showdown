--!strict

local jecs = require("@packages/jecs")

export type ProjectileFilter = {
	instances: { Instance },
}

return {
	ProjectileFilter = jecs.component() :: jecs.Id<ProjectileFilter>,
	ProjectileHidden = jecs.tag(),
}
