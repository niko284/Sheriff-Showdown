local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Matter = require(ReplicatedStorage.packages.Matter)

local Gun = Matter.component("Gun", {
	LocalCooldownMillis = 2000, -- How long does the gun have to wait before it can shoot again?

	-- Store other information about the gun here like:
	Damage = 25,
	BulletLifeTime = 2, -- How long does the bullet last before it despawns?

	MaxCapacity = 10, -- How many bullets can the gun hold before automatically reloading?
	ReloadTime = 1, -- How long does it take to reload the gun?
	CurrentCapacity = 10, -- How many bullets are currently in the gun?

	BulletSpeed = 100, -- How fast do the bullets travel? (in studs per second)
})

return Gun
