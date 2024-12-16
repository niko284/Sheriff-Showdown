local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Matter = require(ReplicatedStorage.packages.Matter)

-- guns are only replicated from the server to the client when they are equipped, so it's less expensive to store some of the bullet information on the gun itself.

local Gun = Matter.component("Gun", {
	LocalCooldownMillis = 200, -- How long does the gun have to wait before it can shoot again?

	-- Store other information about the gun here like:
	Damage = 25,
	CriticalDamage = {
		Head = 100,
	},

	BulletLifeTime = 0.001, -- How long does the bullet last before it despawns?

	MaxCapacity = 10, -- How many bullets can the gun hold before automatically reloading?
	ReloadTime = 1, -- How long does it take to reload the gun?
	CurrentCapacity = 10, -- How many bullets are currently in the gun?

	BulletSpeed = 10000, -- How fast do the bullets travel? (in studs per second)

	-- The sound that the gun makes when it shoots.
	BulletSoundId = 1905367471,

	KnockStrength = 50,
})

return Gun
