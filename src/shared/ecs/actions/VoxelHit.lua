--!strict

local BlinkServer = require("@server/modules/BlinkServer")
local Components = require("@ecs/components")
local Types = require("@constants/Types")
local VoxelBuffer = require("@utilities/VoxelBuffer")
local t = require("@packages/t")

type VoxelHitPayload = {
	targetEntityId: number,
	hitPosition: Vector3,
} & Types.GenericPayload

local function collectDestroyedIndices(
	grid: Components.VoxelGrid,
	gridOrigin: CFrame,
	hitWorld: Vector3,
	destruction: Components.DestructionRadius
): buffer
	local localPos = gridOrigin:PointToObjectSpace(hitWorld)
	local halfSize = Vector3.new(grid.sizeX, grid.sizeY, grid.sizeZ) * grid.cellSize * 0.5
	local cellOrigin = localPos + halfSize

	local destroyed: { number } = {}

	local radiusCells = math.ceil(destruction.radius / grid.cellSize)
	local cx = math.floor(cellOrigin.X / grid.cellSize)
	local cy = math.floor(cellOrigin.Y / grid.cellSize)
	local cz = math.floor(cellOrigin.Z / grid.cellSize)

	for dz = -radiusCells, radiusCells do
		for dy = -radiusCells, radiusCells do
			for dx = -radiusCells, radiusCells do
				local x, y, z = cx + dx, cy + dy, cz + dz
				if x < 0 or x >= grid.sizeX or y < 0 or y >= grid.sizeY or z < 0 or z >= grid.sizeZ then
					continue
				end

				local inRange = false
				if destruction.shape == "Sphere" then
					local dist =
						Vector3.new(dx, dy, dz).Magnitude * grid.cellSize
					inRange = dist <= destruction.radius
				else
					inRange = math.abs(dx) * grid.cellSize <= destruction.radius
						and math.abs(dy) * grid.cellSize <= destruction.radius
						and math.abs(dz) * grid.cellSize <= destruction.radius
				end

				if inRange then
					local idx = VoxelBuffer.flatIndex(x, y, z, grid.sizeX, grid.sizeY)
					if VoxelBuffer.get(grid.data, idx) then
						table.insert(destroyed, idx)
					end
				end
			end
		end
	end

	local indicesBuf = buffer.create(#destroyed * 4)
	for i, idx in destroyed do
		buffer.writeu32(indicesBuf, (i - 1) * 4, idx)
	end

	return indicesBuf
end

return {
	process = function(world, player, actionPayload)
		if not world:contains(actionPayload.targetEntityId) then
			warn("Invalid voxel entity id")
			return
		end

		local grid: Components.VoxelGrid? = world:get(actionPayload.targetEntityId, Components.VoxelGrid)
		if not grid then
			warn("Target entity has no VoxelGrid")
			return
		end

		local transform = world:get(actionPayload.targetEntityId, Components.Transform)
		local gridOrigin = transform and transform.cframe or CFrame.identity

		-- Find the projectile that made this hit to get DestructionRadius
		local destructionRadius: Components.DestructionRadius? = nil
		for eid, _proj, identifier: Components.Identifier, owner: Components.Owner in
			world:query(Components.Projectile, Components.Identifier, Components.Owner)
		do
			if identifier.uuid == actionPayload.actionId and owner.OwnedBy == player then
				destructionRadius = world:get(eid, Components.DestructionRadius)
				world:delete(eid)
				break
			end
		end

		if not destructionRadius then
			return
		end

		local hitWorld = actionPayload.hitPosition
		if not hitWorld then
			return
		end

		local indicesBuf = collectDestroyedIndices(grid, gridOrigin, hitWorld, destructionRadius)
		if buffer.len(indicesBuf) == 0 then
			return
		end

		VoxelBuffer.clearIndices(grid.data, indicesBuf)
		world:set(actionPayload.targetEntityId, Components.VoxelGrid, grid)

		BlinkServer.VoxelDestroyCells.FireAll({
			entityId = actionPayload.targetEntityId,
			indices = indicesBuf,
			hitPosition = hitWorld,
			explosionForce = destructionRadius.explosionForce,
			debrisLifetime = destructionRadius.debrisLifetime,
		})
	end,
	validatePayload = t.strictInterface({
		action = t.literal("VoxelHit"),
		actionId = t.string,
		targetEntityId = t.number,
		hitPosition = t.Vector3,
	}),
	afterProcess = {},
} :: Types.Action<VoxelHitPayload>
