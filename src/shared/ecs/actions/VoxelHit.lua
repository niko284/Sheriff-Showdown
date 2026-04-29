--!strict

local jecs = require("@packages/jecs")
local replecs = require("@packages/replecs")

local BlinkServer = require("@server/modules/BlinkServer")
local Components = require("@ecs/components")
local Types = require("@constants/Types")
local Util = require("@ecs/Util")
local VoxelBuffer = require("@utilities/VoxelBuffer")
local VoxelManager = require("@server/ecs/VoxelManager")
local VoxelOriginalData = require("@ecs/VoxelOriginalData")
local t = require("@packages/t")

local function hash01(x: number, y: number, z: number, seed: number): number
	local value = math.sin(x * 12.9898 + y * 78.233 + z * 37.719 + seed * 0.01337) * 43758.5453
	return value - math.floor(value)
end

-- Within an entity's grid, lateral support is only valid where the cell was
-- originally an "overhang" (no solid in its column below). Trunk-style
-- columns require direct-below support so destruction propagates up cleanly.
local LATERAL_OFFSETS = {
	{ 1, 0 },
	{ -1, 0 },
	{ 0, 1 },
	{ 0, -1 },
	{ 1, 1 },
	{ 1, -1 },
	{ -1, 1 },
	{ -1, -1 },
}

local function collectLooseIndices(
	data: buffer,
	originalData: buffer,
	anchorMask: buffer,
	sizeX: number,
	sizeY: number,
	sizeZ: number
): buffer
	local sliceSize = sizeX * sizeY
	local bufBytes = math.ceil(sizeX * sizeY * sizeZ / 8)

	local isOverhang = buffer.create(bufBytes)
	for z = 0, sizeZ - 1 do
		for x = 0, sizeX - 1 do
			local seenSolidBelow = false
			for y = 0, sizeY - 1 do
				local idx = VoxelBuffer.flatIndex(x, y, z, sizeX, sizeY)
				if not seenSolidBelow then
					VoxelBuffer.set(isOverhang, idx, true)
				end
				if VoxelBuffer.get(originalData, idx) then
					seenSolidBelow = true
				end
			end
		end
	end

	local supported = buffer.create(bufBytes)

	for z = 0, sizeZ - 1 do
		for x = 0, sizeX - 1 do
			local idx = VoxelBuffer.flatIndex(x, 0, z, sizeX, sizeY)
			if VoxelBuffer.get(data, idx) and VoxelBuffer.get(anchorMask, idx) then
				VoxelBuffer.set(supported, idx, true)
			end
		end
	end

	for y = 1, sizeY - 1 do
		local layerSeeds: { number } = {}

		for z = 0, sizeZ - 1 do
			for x = 0, sizeX - 1 do
				local idx = VoxelBuffer.flatIndex(x, y, z, sizeX, sizeY)
				if not VoxelBuffer.get(data, idx) then
					continue
				end
				local belowIdx = VoxelBuffer.flatIndex(x, y - 1, z, sizeX, sizeY)
				if VoxelBuffer.get(supported, belowIdx) then
					VoxelBuffer.set(supported, idx, true)
					table.insert(layerSeeds, idx)
				end
			end
		end

		local head = 1
		while head <= #layerSeeds do
			local idx = layerSeeds[head]
			head += 1

			local iz = math.floor(idx / sliceSize)
			local rem = idx % sliceSize
			local ix = rem % sizeX

			for _, off in LATERAL_OFFSETS do
				local nx, nz = ix + off[1], iz + off[2]
				if nx < 0 or nx >= sizeX or nz < 0 or nz >= sizeZ then
					continue
				end
				local nIdx = VoxelBuffer.flatIndex(nx, y, nz, sizeX, sizeY)
				if
					VoxelBuffer.get(data, nIdx)
					and not VoxelBuffer.get(supported, nIdx)
					and VoxelBuffer.get(isOverhang, nIdx)
				then
					VoxelBuffer.set(supported, nIdx, true)
					table.insert(layerSeeds, nIdx)
				end
			end
		end
	end

	local loose: { number } = {}
	for z = 0, sizeZ - 1 do
		for y = 1, sizeY - 1 do
			for x = 0, sizeX - 1 do
				local idx = VoxelBuffer.flatIndex(x, y, z, sizeX, sizeY)
				if VoxelBuffer.get(data, idx) and not VoxelBuffer.get(supported, idx) then
					table.insert(loose, idx)
				end
			end
		end
	end

	local looseBuf = buffer.create(#loose * 4)
	for i, idx in loose do
		buffer.writeu32(looseBuf, (i - 1) * 4, idx)
	end
	return looseBuf
end

local CONNECTED_NEIGHBORS = {
	{ 1, 0, 0 },
	{ -1, 0, 0 },
	{ 0, 1, 0 },
	{ 0, -1, 0 },
	{ 0, 0, 1 },
	{ 0, 0, -1 },
}

local function findConnectedComponents(
	indicesBuf: buffer,
	sizeX: number,
	sizeY: number,
	sizeZ: number
): { { number } }
	local count = math.floor(buffer.len(indicesBuf) / 4)
	if count == 0 then
		return {}
	end

	local sliceSize = sizeX * sizeY
	local set: { [number]: boolean } = {}
	for i = 0, count - 1 do
		set[buffer.readu32(indicesBuf, i * 4)] = true
	end

	local visited: { [number]: boolean } = {}
	local components: { { number } } = {}

	for seed in pairs(set) do
		if visited[seed] then
			continue
		end
		local component: { number } = {}
		local queue: { number } = { seed }
		visited[seed] = true

		local head = 1
		while head <= #queue do
			local idx = queue[head]
			head += 1
			table.insert(component, idx)

			local iz = math.floor(idx / sliceSize)
			local rem = idx % sliceSize
			local iy = math.floor(rem / sizeX)
			local ix = rem % sizeX

			for _, off in CONNECTED_NEIGHBORS do
				local nx, ny, nz = ix + off[1], iy + off[2], iz + off[3]
				if nx < 0 or nx >= sizeX or ny < 0 or ny >= sizeY or nz < 0 or nz >= sizeZ then
					continue
				end
				local nIdx = nx + ny * sizeX + nz * sliceSize
				if set[nIdx] and not visited[nIdx] then
					visited[nIdx] = true
					table.insert(queue, nIdx)
				end
			end
		end

		table.insert(components, component)
	end

	return components
end

-- Spawns a new voxel entity holding the given connected component of cells.
-- The entity's source is a tiny invisible Part placed at the component's
-- centroid; the visible body is the greedy-meshed members built by
-- VoxelManager.refreshEntity. Section formation later welds those members
-- into a falling rigid assembly. Bullets hit the members like any other
-- voxel entity — the new entity is not "debris" with a lifetime.
local function spawnLooseEntity(
	world: any,
	sourceGrid: Components.VoxelGrid,
	sourceCFrame: CFrame,
	component: { number },
	color: Color3,
	material: Enum.Material
): number?
	if #component == 0 then
		return nil
	end

	local sliceSize = sourceGrid.sizeX * sourceGrid.sizeY
	local minX, minY, minZ = math.huge, math.huge, math.huge
	local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge
	for _, idx in component do
		local iz = math.floor(idx / sliceSize)
		local rem = idx % sliceSize
		local iy = math.floor(rem / sourceGrid.sizeX)
		local ix = rem % sourceGrid.sizeX
		if ix < minX then
			minX = ix
		end
		if iy < minY then
			minY = iy
		end
		if iz < minZ then
			minZ = iz
		end
		if ix > maxX then
			maxX = ix
		end
		if iy > maxY then
			maxY = iy
		end
		if iz > maxZ then
			maxZ = iz
		end
	end

	local newSizeX = maxX - minX + 1
	local newSizeY = maxY - minY + 1
	local newSizeZ = maxZ - minZ + 1
	local newBuffer = buffer.create(math.ceil(newSizeX * newSizeY * newSizeZ / 8))
	for _, idx in component do
		local iz = math.floor(idx / sliceSize)
		local rem = idx % sliceSize
		local iy = math.floor(rem / sourceGrid.sizeX)
		local ix = rem % sourceGrid.sizeX
		local newIdx = (ix - minX) + (iy - minY) * newSizeX + (iz - minZ) * newSizeX * newSizeY
		VoxelBuffer.set(newBuffer, newIdx, true)
	end

	local cellSize = sourceGrid.cellSize
	local sourceHalf = Vector3.new(sourceGrid.sizeX, sourceGrid.sizeY, sourceGrid.sizeZ) * cellSize * 0.5
	local componentCenterLocal = Vector3.new(
		minX * cellSize + newSizeX * cellSize * 0.5 - sourceHalf.X,
		minY * cellSize + newSizeY * cellSize * 0.5 - sourceHalf.Y,
		minZ * cellSize + newSizeZ * cellSize * 0.5 - sourceHalf.Z
	)
	local newCFrame = sourceCFrame * CFrame.new(componentCenterLocal)

	-- Tiny invisible Part: just an entity-frame anchor that the mesh members
	-- (built by VoxelManager.refreshEntity) hang off of. Its CFrame becomes
	-- meaningful after section formation: it gets welded to the section
	-- anchor and the mesh code reads .CFrame as the entity's current pose.
	local sizeWorld = Vector3.new(newSizeX, newSizeY, newSizeZ) * cellSize
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Color = color
	part.Material = material
	part.Transparency = 1
	part.Size = sizeWorld
	part.CFrame = newCFrame
	part.Parent = workspace

	local eid = world:entity()
	world:add(eid, replecs.networked)
	world:set(eid, Components.Renderable, { instance = part })
	world:add(eid, jecs.pair(replecs.reliable, Components.Renderable))
	-- Intentionally NO Transform component on falling entities: the source's
	-- CFrame is replicated natively by Roblox via the welded assembly, and
	-- replecs Transform updates would fire client-side PivotTo each tick,
	-- yanking the welded source back to its spawn pose. Code paths that
	-- need the entity's pose read renderable.instance.CFrame instead.
	world:set(eid, Components.VoxelGrid, {
		data = newBuffer,
		sizeX = newSizeX,
		sizeY = newSizeY,
		sizeZ = newSizeZ,
		cellSize = cellSize,
	})
	world:add(eid, jecs.pair(replecs.reliable, Components.VoxelGrid))
	world:add(eid, Components.Voxelized)
	world:add(eid, jecs.pair(replecs.reliable, Components.Voxelized))
	part:SetAttribute("voxelEntityId", eid)

	-- Build the mesh members synchronously so subsequent cascade raycasts hit
	-- their up-to-date positions, and so section formation has parts to weld.
	VoxelManager.refreshEntity(eid, {
		data = newBuffer,
		sizeX = newSizeX,
		sizeY = newSizeY,
		sizeZ = newSizeZ,
		cellSize = cellSize,
	}, part)

	return eid
end

-- Probes a thin slab above the entity's source to find OTHER voxel entities
-- sitting on top of it. Used to bound the cascade to the dependency chain.
local function findEntitiesAbove(world: any, eid: number): { number }
	local renderable = world:get(eid, Components.Renderable)
	if not renderable then
		return {}
	end
	local instance = renderable.instance
	if not instance:IsA("BasePart") then
		return {}
	end
	local source = instance :: BasePart

	local probeHeight = 3
	local horizontalMargin = 0.5
	local probeCFrame = source.CFrame * CFrame.new(0, source.Size.Y * 0.5 + probeHeight * 0.5, 0)
	local probeSize =
		Vector3.new(source.Size.X + horizontalMargin * 2, probeHeight, source.Size.Z + horizontalMargin * 2)

	local overlap = OverlapParams.new()
	overlap.FilterDescendantsInstances = { source }
	overlap.FilterType = Enum.RaycastFilterType.Exclude
	overlap.MaxParts = 64

	local touching = workspace:GetPartBoundsInBox(probeCFrame, probeSize, overlap)
	local seen: { [number]: boolean } = {}
	local entities: { number } = {}
	for _, part in touching do
		local otherEid = part:GetAttribute("voxelEntityId") :: number?
		if otherEid and not seen[otherEid] and world:contains(otherEid :: any) then
			seen[otherEid] = true
			table.insert(entities, otherEid)
		end
	end

	return entities
end

-- For each y=0 cell, raycast straight down by ~one cell. The cell is anchored
-- if it lands on a non-voxel anchored part (real ground) or a still-solid
-- cell of another non-falling voxel entity. Falling entities cannot anchor
-- anything because they're themselves in motion.
local function computeAnchorMask(world: any, eid: number, grid: Components.VoxelGrid, gridOrigin: CFrame): buffer
	local bufBytes = math.ceil(grid.sizeX * grid.sizeY * grid.sizeZ / 8)
	local mask = buffer.create(bufBytes)

	local renderable = world:get(eid, Components.Renderable)
	local sourceInstance = renderable and renderable.instance :: BasePart? or nil

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = sourceInstance and { sourceInstance } or {}
	rayParams.IgnoreWater = true

	local halfSize = Vector3.new(grid.sizeX, grid.sizeY, grid.sizeZ) * grid.cellSize * 0.5
	local probeDir = Vector3.new(0, -grid.cellSize * 2, 0)

	for z = 0, grid.sizeZ - 1 do
		for x = 0, grid.sizeX - 1 do
			local idx = VoxelBuffer.flatIndex(x, 0, z, grid.sizeX, grid.sizeY)
			if not VoxelBuffer.get(grid.data, idx) then
				continue
			end

			local localCenter = Vector3.new(
				(x + 0.5) * grid.cellSize - halfSize.X,
				grid.cellSize * 0.5 - halfSize.Y,
				(z + 0.5) * grid.cellSize - halfSize.Z
			)
			local worldCenter = gridOrigin:PointToWorldSpace(localCenter)

			local raycast = workspace:Raycast(worldCenter, probeDir, rayParams)
			if not raycast then
				continue
			end

			local hitInstance = raycast.Instance
			local hitVoxelEid = hitInstance:GetAttribute("voxelEntityId") :: number?
			local isAnchored = false

			if hitVoxelEid and world:contains(hitVoxelEid :: any) then
				if not VoxelManager.isFalling(hitVoxelEid :: any) then
					local hitGrid: Components.VoxelGrid? =
						world:get(hitVoxelEid :: any, Components.VoxelGrid)
					if hitGrid then
						local hitRenderable = world:get(hitVoxelEid :: any, Components.Renderable)
						local hitSourcePart = hitRenderable and hitRenderable.instance :: BasePart?
						local hitCFrame: CFrame
						if hitSourcePart and hitSourcePart:IsA("BasePart") then
							hitCFrame = hitSourcePart.CFrame
						else
							local hitTransform = world:get(hitVoxelEid :: any, Components.Transform)
							hitCFrame = hitTransform and hitTransform.cframe or CFrame.identity
						end
						local hitLocalPos = hitCFrame:PointToObjectSpace(raycast.Position)
						local hitHalf = Vector3.new(hitGrid.sizeX, hitGrid.sizeY, hitGrid.sizeZ)
							* hitGrid.cellSize
							* 0.5
						local hitCellOrigin = hitLocalPos + hitHalf
						local hx = math.floor(hitCellOrigin.X / hitGrid.cellSize)
						local hy = math.floor(hitCellOrigin.Y / hitGrid.cellSize)
						local hz = math.floor(hitCellOrigin.Z / hitGrid.cellSize)
						if
							hx >= 0
							and hx < hitGrid.sizeX
							and hy >= 0
							and hy < hitGrid.sizeY
							and hz >= 0
							and hz < hitGrid.sizeZ
						then
							local hitIdx = VoxelBuffer.flatIndex(hx, hy, hz, hitGrid.sizeX, hitGrid.sizeY)
							isAnchored = VoxelBuffer.get(hitGrid.data, hitIdx)
						end
					end
				end
			else
				isAnchored = hitInstance.Anchored
			end

			if isAnchored then
				VoxelBuffer.set(mask, idx, true)
			end
		end
	end

	return mask
end

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

	-- Hits near the bottom get a bigger destruction sphere so the trunk-style
	-- cross-section severs cleanly and the cascade can flag everything above.
	local heightFraction = cellOrigin.Y / (grid.sizeY * grid.cellSize)
	local rootBoost = 1 + math.max(0, 0.3 - heightFraction) * 6

	local minWorldRadius = grid.cellSize
	local baseDestructionRadius = math.max(destruction.radius, minWorldRadius)
	local effectiveDestructionRadius = baseDestructionRadius * rootBoost
	local radiusCells = math.ceil(effectiveDestructionRadius / grid.cellSize)
	local cx = math.floor(cellOrigin.X / grid.cellSize)
	local cy = math.floor(cellOrigin.Y / grid.cellSize)
	local cz = math.floor(cellOrigin.Z / grid.cellSize)
	local variance = destruction.variance or 0.35
	local roughness = destruction.roughness or 0.25
	local seed = destruction.seed or 0
	local baseRadius = effectiveDestructionRadius * (0.9 + hash01(cx, cy, cz, seed) * 0.2)

	for dz = -radiusCells, radiusCells do
		for dy = -radiusCells, radiusCells do
			for dx = -radiusCells, radiusCells do
				local x, y, z = cx + dx, cy + dy, cz + dz
				if x < 0 or x >= grid.sizeX or y < 0 or y >= grid.sizeY or z < 0 or z >= grid.sizeZ then
					continue
				end

				local inRange = false
				if destruction.shape == "Sphere" then
					local dist = Vector3.new(dx, dy, dz).Magnitude * grid.cellSize
					local noise = hash01(x, y, z, seed)
					local effectiveRadius = baseRadius * (1 + (noise - 0.5) * 2 * roughness)
					local strayRadius = effectiveRadius + effectiveDestructionRadius * variance * 0.35

					if dist <= effectiveRadius then
						local innerRadius = effectiveRadius * 0.55
						if dist <= innerRadius then
							inRange = true
						else
							local shellAlpha = math.clamp(
								(dist - innerRadius) / math.max(effectiveRadius - innerRadius, 0.001),
								0,
								1
							)
							local pocketChance = shellAlpha * (0.15 + hash01(x + 17, y + 31, z + 47, seed) * 0.4)
							inRange = hash01(x + 101, y + 211, z + 307, seed) >= pocketChance
						end
					elseif dist <= strayRadius then
						local scatterChance = (
							1
							- math.clamp(
								(dist - effectiveRadius) / math.max(strayRadius - effectiveRadius, 0.001),
								0,
								1
							)
						) * (0.08 + variance * 0.2)
						inRange = hash01(x + 401, y + 503, z + 601, seed) < scatterChance
					end
				else
					local axisRadius = baseRadius * (1 + (hash01(x, y, z, seed) - 0.5) * 2 * roughness)
					inRange = math.abs(dx) * grid.cellSize <= axisRadius
						and math.abs(dy) * grid.cellSize <= axisRadius
						and math.abs(dz) * grid.cellSize <= axisRadius
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

local function isBufferEmpty(buf: buffer): boolean
	for i = 0, buffer.len(buf) - 1 do
		if buffer.readu8(buf, i) ~= 0 then
			return false
		end
	end
	return true
end

local function applyGridChange(world: any, eid: number, newData: buffer, grid: Components.VoxelGrid)
	if isBufferEmpty(newData) then
		-- Empty grid: tear the entity down. Renderable OnRemove destroys the
		-- source instance; VoxelGrid OnRemove triggers VoxelManager.cleanupEntity.
		world:delete(eid :: any)
		return
	end

	world:set(eid :: any, Components.VoxelGrid, {
		data = newData,
		sizeX = grid.sizeX,
		sizeY = grid.sizeY,
		sizeZ = grid.sizeZ,
		cellSize = grid.cellSize,
	})

	local renderable = world:get(eid :: any, Components.Renderable)
	local sourcePart = renderable and renderable.instance :: BasePart?
	if sourcePart and sourcePart:IsA("BasePart") then
		VoxelManager.refreshEntity(eid, {
			data = newData,
			sizeX = grid.sizeX,
			sizeY = grid.sizeY,
			sizeZ = grid.sizeZ,
			cellSize = grid.cellSize,
		}, sourcePart)
	end
end

return {
	process = function(world, player, actionPayload)
		if not world:contains(actionPayload.targetEntityId) then
			return
		end

		local grid: Components.VoxelGrid? = world:get(actionPayload.targetEntityId, Components.VoxelGrid)
		if not grid then
			return
		end

		-- Source CFrame is the live pose (welded to a section anchor for
		-- falling entities, so it tracks current physics). Transform component
		-- is frozen at spawn for falling entities and doesn't exist on the
		-- new loose entities at all, so prefer the source.
		local renderableTarget = world:get(actionPayload.targetEntityId, Components.Renderable)
		local sourcePartTarget = renderableTarget and renderableTarget.instance :: BasePart?
		local gridOrigin: CFrame
		if sourcePartTarget and sourcePartTarget:IsA("BasePart") then
			gridOrigin = sourcePartTarget.CFrame
		else
			local transform = world:get(actionPayload.targetEntityId, Components.Transform)
			gridOrigin = transform and transform.cframe or CFrame.identity
		end

		local destructionRadius: Components.DestructionRadius? = nil
		for eid, _proj, identifier: Components.Identifier in
			world:query(Components.Projectile, Components.Identifier)
		do
			if identifier.uuid == actionPayload.actionId and Util.GetOwnerPlayer(world, eid) == player then
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

		-- Track every existing falling section we touch this action so we
		-- can re-DFSWeld each at the end. After members get destroyed, the
		-- surviving members may no longer be one connected component, and
		-- without reform they'd stay rigidly attached through the invisible
		-- anchor (visible as "welded chunks with huge gaps").
		local affectedSections: { [BasePart]: true } = {}
		local function captureSection(eid: number)
			local anchor = VoxelManager.getSectionAnchor(eid)
			if anchor then
				affectedSections[anchor] = true
			end
		end

		-- Direct destruction: update the target's grid in place.
		captureSection(actionPayload.targetEntityId)
		local newData = VoxelBuffer.clone(grid.data)
		VoxelBuffer.clearIndices(newData, indicesBuf)
		applyGridChange(world, actionPayload.targetEntityId, newData, grid)

		-- Explosion debris (purely visual, client-side).
		BlinkServer.VoxelDestroyCells.FireAll({
			entityId = actionPayload.targetEntityId,
			indices = indicesBuf,
			hitPosition = hitWorld,
			explosionForce = destructionRadius.explosionForce,
			debrisLifetime = destructionRadius.debrisLifetime,
		})

		-- Cascade: walk the dependency chain. For each entity whose cells
		-- lost support, extract those cells into NEW entities. Mesh members
		-- are built synchronously so subsequent raycasts see post-destruction
		-- state. After the BFS, a single section-formation pass DFS-welds
		-- ALL the new entities' members into rigid falling assemblies.
		local MAX_CASCADED_ENTITIES = 16
		local MAX_SPAWNED_PER_STEP = 8
		local MIN_COMPONENT_CELLS = 2

		local processed: { [number]: boolean } = {}
		local queue: { number } = { actionPayload.targetEntityId }
		local processedCount = 0
		local newEntities: { [number]: true } = {}

		while #queue > 0 and processedCount < MAX_CASCADED_ENTITIES do
			local current = table.remove(queue, 1) :: number
			if processed[current] then
				continue
			end
			processed[current] = true
			processedCount += 1

			if not world:contains(current :: any) then
				continue
			end
			-- Falling entities are already unsupported and welded into a
			-- section; don't re-evaluate or fragment them further.
			if VoxelManager.isFalling(current) then
				continue
			end

			local gridComp: Components.VoxelGrid? = world:get(current :: any, Components.VoxelGrid)
			if not gridComp then
				continue
			end

			local entityRenderableForCFrame = world:get(current :: any, Components.Renderable)
			local entitySourceForCFrame = entityRenderableForCFrame
				and entityRenderableForCFrame.instance :: BasePart?
			local entityCFrame: CFrame
			if entitySourceForCFrame and entitySourceForCFrame:IsA("BasePart") then
				entityCFrame = entitySourceForCFrame.CFrame
			else
				local entityTransform = world:get(current :: any, Components.Transform)
				entityCFrame = entityTransform and entityTransform.cframe or CFrame.identity
			end
			local anchorMask = computeAnchorMask(world, current, gridComp, entityCFrame)
			local entityOriginal = VoxelOriginalData.get(current) or gridComp.data
			local entityLoose = collectLooseIndices(
				gridComp.data,
				entityOriginal,
				anchorMask,
				gridComp.sizeX,
				gridComp.sizeY,
				gridComp.sizeZ
			)

			if buffer.len(entityLoose) == 0 then
				continue
			end

			local entityRenderable = world:get(current :: any, Components.Renderable)
			local entitySource = entityRenderable and entityRenderable.instance :: BasePart?
			local entityColor = entitySource and entitySource.Color or Color3.new(0.6, 0.6, 0.6)
			local entityMaterial = entitySource and entitySource.Material or Enum.Material.SmoothPlastic

			local components =
				findConnectedComponents(entityLoose, gridComp.sizeX, gridComp.sizeY, gridComp.sizeZ)
			table.sort(components, function(a, b)
				return #a > #b
			end)

			local spawnedThisStep = 0
			for _, component in components do
				if spawnedThisStep >= MAX_SPAWNED_PER_STEP then
					break
				end
				if #component < MIN_COMPONENT_CELLS then
					break
				end
				local newEid = spawnLooseEntity(
					world,
					gridComp,
					entityCFrame,
					component,
					entityColor,
					entityMaterial
				)
				if newEid then
					newEntities[newEid] = true
				end
				spawnedThisStep += 1
			end

			-- Clear ALL loose cells from the parent (including ones too small
			-- to spawn as a separate entity — they just disappear).
			captureSection(current)
			local cascadedData = VoxelBuffer.clone(gridComp.data)
			VoxelBuffer.clearIndices(cascadedData, entityLoose)
			applyGridChange(world, current, cascadedData, gridComp)

			for _, aboveEid in findEntitiesAbove(world, current) do
				if not processed[aboveEid] then
					table.insert(queue, aboveEid)
				end
			end
		end

		-- All new loose entities formed by this destruction get DFS-welded
		-- into rigid falling assemblies. Members that touch (within epsilon)
		-- across entity boundaries fuse into one section so multi-part
		-- structures fall as a unit.
		if next(newEntities) then
			VoxelManager.formSection(world, newEntities)
		end

		-- Re-DFSWeld every existing falling section we touched. Members that
		-- got destroyed may have been the bridge holding two halves together;
		-- if the survivors aren't one connected component anymore, the
		-- section gets torn down and rebuilt as separate sections.
		for anchor in affectedSections do
			VoxelManager.reformSection(world, anchor)
		end
	end,
	validatePayload = t.strictInterface({
		action = t.literal("VoxelHit"),
		actionId = t.string,
		targetEntityId = t.number,
		hitPosition = t.Vector3,
	}),
	afterProcess = {},
} :: Types.Action<VoxelHitPayload>
