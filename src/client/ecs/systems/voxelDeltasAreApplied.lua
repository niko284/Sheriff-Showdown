--!strict

local jecs = require("@packages/jecs")

local BlinkClient = require("@client/modules/BlinkClient")
local Components = require("@ecs/components")
local VoxelBuffer = require("@utilities/VoxelBuffer")

local MAX_DEBRIS = 64

type VoxelDelta = {
	entityId: number,
	indices: buffer,
	hitPosition: Vector3,
	explosionForce: number,
	debrisLifetime: number,
}

type State = {
	replecsClient: any,
	pendingVoxelDeltas: { VoxelDelta }?,
}

local function spawnDebris(
	grid: Components.VoxelGrid,
	originCFrame: CFrame,
	indices: buffer,
	hitPosition: Vector3,
	explosionForce: number,
	debrisLifetime: number,
	color: Color3,
	material: Enum.Material
)
	local count = math.min(math.floor(buffer.len(indices) / 4), MAX_DEBRIS)
	if count == 0 or explosionForce <= 0 then
		return
	end

	local halfSize = Vector3.new(grid.sizeX, grid.sizeY, grid.sizeZ) * grid.cellSize * 0.5
	local debrisSize = Vector3.one * grid.cellSize * 0.85

	-- If more cells than MAX_DEBRIS, stride through them evenly
	local stride = math.max(1, math.floor(buffer.len(indices) / 4 / count))

	for i = 0, count - 1 do
		local rawIdx = buffer.readu32(indices, i * stride * 4)
		local iz = math.floor(rawIdx / (grid.sizeX * grid.sizeY))
		local rem = rawIdx % (grid.sizeX * grid.sizeY)
		local iy = math.floor(rem / grid.sizeX)
		local ix = rem % grid.sizeX

		local localPos = Vector3.new(
			(ix + 0.5) * grid.cellSize - halfSize.X,
			(iy + 0.5) * grid.cellSize - halfSize.Y,
			(iz + 0.5) * grid.cellSize - halfSize.Z
		)
		local worldPos = originCFrame:PointToWorldSpace(localPos)

		local dir = worldPos - hitPosition
		local dist = dir.Magnitude
		dir = dist > 0.01 and dir.Unit or Vector3.new(math.random() - 0.5, 1, math.random() - 0.5).Unit

		-- Linear falloff: cells further from center get slightly less force
		local falloffScale = 1 - math.clamp(dist / (grid.cellSize * 6), 0, 0.5)
		local speed = explosionForce * falloffScale

		local spread = Vector3.new(
			(math.random() - 0.5) * 0.25,
			math.random() * 0.4,
			(math.random() - 0.5) * 0.25
		)
		local velocity = (dir + spread).Unit * speed

		local part = Instance.new("Part")
		part.Anchored = false
		part.CanCollide = false
		part.CastShadow = false
		part.CollisionGroup = "VoxelMesh"
		part.Color = color
		part.Material = material
		part.Size = debrisSize
		part.CFrame = CFrame.new(worldPos)
		part.Parent = workspace
		part.AssemblyLinearVelocity = velocity

		task.delay(debrisLifetime, part.Destroy, part)
	end
end

local function voxelDeltasAreApplied(world: jecs.World, state: State)
	if not state.pendingVoxelDeltas then
		state.pendingVoxelDeltas = {}
		BlinkClient.VoxelDestroyCells.On(function(payload: VoxelDelta)
			table.insert(state.pendingVoxelDeltas :: any, payload)
		end)
	end

	local pending = state.pendingVoxelDeltas :: { VoxelDelta }
	if #pending == 0 then
		return
	end
	state.pendingVoxelDeltas = {}

	local replecsClient = state.replecsClient

	for _, delta in pending do
		local clientEid = replecsClient and replecsClient:get_client_entity(delta.entityId) or delta.entityId
		if not world:contains(clientEid) then
			continue
		end

		local grid: Components.VoxelGrid? = world:get(clientEid, Components.VoxelGrid)
		if not grid then
			continue
		end

		local renderable = world:get(clientEid, Components.Renderable)
		local sourcePart = renderable and renderable.instance :: BasePart?
		local transform = world:get(clientEid, Components.Transform)
		local originCFrame = transform and transform.cframe or CFrame.identity

		spawnDebris(
			grid,
			originCFrame,
			delta.indices,
			delta.hitPosition,
			delta.explosionForce,
			delta.debrisLifetime,
			sourcePart and sourcePart.Color or Color3.new(0.6, 0.6, 0.6),
			sourcePart and sourcePart.Material or Enum.Material.SmoothPlastic
		)

		VoxelBuffer.clearIndices(grid.data, delta.indices)
		world:set(clientEid, Components.VoxelGrid, grid)
	end
end

return voxelDeltasAreApplied
