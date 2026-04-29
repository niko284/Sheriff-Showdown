--!strict

local jecs = require("@packages/jecs")

local Components = require("@ecs/components")
local VoxelBuffer = require("@utilities/VoxelBuffer")

local Util = {}

function Util.GetTargetEntityIdFromPlayer(world: jecs.World, player: Player): jecs.Entity?
	for eid, _, playerData in world:query(Components.Target, Components.Player) do
		if playerData.player == player then
			return eid
		end
	end
	return nil
end

function Util.GetOwnerPlayer(world: jecs.World, eid: jecs.Entity): Player?
	local ownerEid = world:target(eid, Components.OwnedBy) or world:target(eid, jecs.ChildOf)
	if not ownerEid then
		return nil
	end
	local playerComp = world:get(ownerEid, Components.Player)
	return playerComp and playerComp.player or nil
end

local function isHitOnDestroyedVoxelCell(world: jecs.World, raycastResult: RaycastResult): boolean
	local voxelEntityId = raycastResult.Instance:GetAttribute("voxelEntityId") :: number?
	if not voxelEntityId or not world:contains(voxelEntityId :: any) then
		return false
	end

	local grid = world:get(voxelEntityId :: any, Components.VoxelGrid)
	if not grid then
		return false
	end

	-- Use the source part's live CFrame (welded to the section anchor for
	-- falling entities, so it tracks current physics). The Transform
	-- component is frozen at spawn for falling entities and absent on the
	-- ones we extract during the cascade.
	local renderable = world:get(voxelEntityId :: any, Components.Renderable)
	local sourcePart = renderable and renderable.instance :: BasePart?
	local gridOrigin: CFrame
	if sourcePart and sourcePart:IsA("BasePart") then
		gridOrigin = sourcePart.CFrame
	else
		local transform = world:get(voxelEntityId :: any, Components.Transform)
		gridOrigin = transform and transform.cframe or CFrame.identity
	end
	local localPos = gridOrigin:PointToObjectSpace(raycastResult.Position)
	local halfSize = Vector3.new(grid.sizeX, grid.sizeY, grid.sizeZ) * grid.cellSize * 0.5
	local cellOrigin = localPos + halfSize
	local cx = math.floor(cellOrigin.X / grid.cellSize)
	local cy = math.floor(cellOrigin.Y / grid.cellSize)
	local cz = math.floor(cellOrigin.Z / grid.cellSize)

	if cx < 0 or cx >= grid.sizeX or cy < 0 or cy >= grid.sizeY or cz < 0 or cz >= grid.sizeZ then
		return false
	end

	local idx = VoxelBuffer.flatIndex(cx, cy, cz, grid.sizeX, grid.sizeY)
	return not VoxelBuffer.get(grid.data, idx)
end

-- Raycasts from origin toward target, transparently passing through destroyed
-- voxel cells. Returns true if the line of sight reaches the target instance.
function Util.IsLineOfSightClear(
	world: jecs.World,
	origin: Vector3,
	dir: Vector3,
	targetInstance: Instance,
	excludeFilter: { Instance }
): boolean
	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = excludeFilter
	rayParams.FilterType = Enum.RaycastFilterType.Exclude

	local destination = origin + dir
	local currentOrigin = origin
	local stepEpsilon = 0.05

	for _ = 1, 8 do
		local remaining = destination - currentOrigin
		if remaining.Magnitude < stepEpsilon * 2 then
			return true
		end

		local raycast = workspace:Raycast(currentOrigin, remaining, rayParams)
		if not raycast then
			return true
		end

		if raycast.Instance:IsDescendantOf(targetInstance) then
			return true
		end

		if isHitOnDestroyedVoxelCell(world, raycast) then
			currentOrigin = raycast.Position + remaining.Unit * stepEpsilon
			continue
		end

		return false
	end

	return false
end

return Util
