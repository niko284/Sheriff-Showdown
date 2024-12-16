local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.packages

local Components = require(ReplicatedStorage.ecs.components)
local Matter = require(Packages.Matter)

local affectsWalkspeed = {
	Components.Slowed,
}

local function collectWalkspeeds(world: Matter.World)
	for id, _target in world:query(Components.Target) do
		local results = { world:get(id, unpack(affectsWalkspeed)) }

		-- NOTE: You can't be tricky by just checking the length of this table!
		-- We MUST iterate over it because the Lua length operator does not work
		-- as you might expect when a table has nil values in it.
		-- See for yourself: Lua says #{nil,nil,nil,1,nil} is 0!

		local modifier = 1

		for _, walkspeedComponent in results do
			local walkspeedModifier = walkspeedComponent.walkspeedMultiplier
			modifier *= walkspeedModifier
		end

		-- The default Roblox walk speed is 16
		local speed = 16 * modifier

		world:insert(
			id,
			Components.WalkSpeed({
				speed = speed,
				modifier = modifier,
			})
		)
	end
end

return collectWalkspeeds
