local Matter = require("@packages/Matter")

local Lifetime = Matter.component("Lifetime", {
	expiry = os.time() + 5, -- 5 seconds default expiry time.
})

return Lifetime
