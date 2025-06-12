local Matter = require("@packages/Matter")

local Owner = Matter.component("Owner", {
	OwnedBy = nil :: Player?,
})

return Owner
