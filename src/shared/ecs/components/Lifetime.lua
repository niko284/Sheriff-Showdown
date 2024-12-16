local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Matter = require(ReplicatedStorage.packages.Matter)

local Lifetime = Matter.component("Lifetime", {
	expiry = os.time() + 5, -- 5 seconds default expiry time.
})

return Lifetime
