--!strict

local TweenService = game:GetService("TweenService")

local jecs = require("@packages/jecs")

local BlinkClient = require("@client/modules/BlinkClient")
local Components = require("@ecs/components")

local MAX_DEBRIS = 64
local DEBRIS_COLLISION_GROUP = "VoxelDebris"
local DEBRIS_SPAWN_OFFSET = 0.3
local FADE_TIME = 0.22
local MIN_FADE_SIZE = Vector3.one * 0.05

local function fadeAndDestroy(part: BasePart, debrisLifetime: number)
	task.delay(math.max(0, debrisLifetime - FADE_TIME), function()
		if not part.Parent then
			return
		end

		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.Anchored = true

		local tween =
			TweenService:Create(part, TweenInfo.new(FADE_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Size = MIN_FADE_SIZE,
				Transparency = 1,
			})
		tween:Play()
		tween.Completed:Once(function()
			part:Destroy()
		end)
	end)
end

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

		local falloffScale = 1 - math.clamp(dist / (grid.cellSize * 6), 0, 0.5)
		local speed = explosionForce * (0.65 + math.random() * 0.35) * falloffScale

		local spread =
			Vector3.new((math.random() - 0.5) * 0.45, 0.3 + math.random() * 0.45, (math.random() - 0.5) * 0.45)
		local velocity = (dir * 0.7 + spread).Unit * speed

		local part = Instance.new("Part")
		part.Anchored = false
		part.CanCollide = true
		part.CanQuery = false
		part.CanTouch = false
		part.CastShadow = false
		part.CollisionGroup = DEBRIS_COLLISION_GROUP
		part.CustomPhysicalProperties = PhysicalProperties.new(1.8, 0.9, 0.08)
		part.Color = color
		part.Material = material
		part.Size = debrisSize
		local spawnOffset = velocity.Unit * (grid.cellSize * DEBRIS_SPAWN_OFFSET) + Vector3.yAxis * (debrisSize.Y * 0.2)
		part.CFrame = CFrame.new(worldPos + spawnOffset)
		part.Parent = workspace
		part.AssemblyLinearVelocity = velocity
		part.AssemblyAngularVelocity =
			Vector3.new((math.random() - 0.5) * 8, (math.random() - 0.5) * 8, (math.random() - 0.5) * 8)

		fadeAndDestroy(part, debrisLifetime)
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

		-- Origin from the source part's live CFrame so debris spawns at the
		-- entity's CURRENT pose. Falling entities don't have a Transform
		-- component (their pose is driven by the welded assembly's physics
		-- replication), and a frozen Transform would drop debris at spawn.
		local originCFrame: CFrame
		if sourcePart and sourcePart:IsA("BasePart") then
			originCFrame = sourcePart.CFrame
		else
			local transform = world:get(clientEid, Components.Transform)
			originCFrame = transform and transform.cframe or CFrame.identity
		end

		local color = sourcePart and sourcePart.Color or Color3.new(0.6, 0.6, 0.6)
		local material = sourcePart and sourcePart.Material or Enum.Material.SmoothPlastic

		spawnDebris(
			grid,
			originCFrame,
			delta.indices,
			delta.hitPosition,
			delta.explosionForce,
			delta.debrisLifetime,
			color,
			material
		)
		-- The server is authoritative for grid state and replicates the
		-- updated VoxelGrid component via replecs. We don't double-write
		-- it here — this system is purely cosmetic explosion debris.
	end
end

return voxelDeltasAreApplied
