--!strict

local jecs = require("@packages/jecs")

local Components = require("@ecs/components")
local GreedyMesh = require("@utilities/GreedyMesh")

local COLLISION_GROUP = "VoxelMesh"

local entityMeshParts: { [number]: { BasePart } } = {}
local entityLastData: { [number]: buffer } = {}

local function rebuildMesh(eid: number, serverEid: number, grid: Components.VoxelGrid, sourcePart: BasePart?)
	local existing = entityMeshParts[eid]
	if existing then
		for _, part in existing do
			part:Destroy()
		end
	end

	local boxes = GreedyMesh(grid.data, grid.sizeX, grid.sizeY, grid.sizeZ)
	local parts: { BasePart } = {}

	local color = sourcePart and sourcePart.Color or Color3.new(0.6, 0.6, 0.6)
	local material = sourcePart and sourcePart.Material or Enum.Material.SmoothPlastic
	local originCFrame = sourcePart and sourcePart.CFrame or CFrame.identity
	local halfGrid = Vector3.new(grid.sizeX, grid.sizeY, grid.sizeZ) * grid.cellSize * 0.5

	for _, box in boxes do
		local boxMin = box.min * grid.cellSize - halfGrid
		local boxMax = (box.max + Vector3.one) * grid.cellSize - halfGrid
		local center = (boxMin + boxMax) * 0.5
		local size = boxMax - boxMin

		local part = Instance.new("Part")
		part.Anchored = true
		part.CanCollide = true
		part.CollisionGroup = COLLISION_GROUP
		part.Color = color
		part.Material = material
		part.Size = size
		part.CFrame = originCFrame * CFrame.new(center)
		-- Tag so projectilesCollide can identify which voxel entity owns this part
		part:SetAttribute("voxelEntityId", serverEid)
		part.Parent = workspace

		table.insert(parts, part)
	end

	entityMeshParts[eid] = parts

	-- Hide the source part; the voxel mesh takes over visuals and collisions
	if sourcePart then
		sourcePart.Transparency = 1
		sourcePart.CanCollide = false
		sourcePart.CastShadow = false
	end
end

local function restoreSourcePart(sourcePart: BasePart?)
	if sourcePart then
		sourcePart.Transparency = 0
		sourcePart.CanCollide = true
		sourcePart.CastShadow = true
	end
end

type State = {
	replecsClient: any,
}

local function voxelMeshesAreRendered(world: jecs.World, state: State)
	local replecsClient = state.replecsClient

	for eid, grid: Components.VoxelGrid in world:query(Components.VoxelGrid) do
		local lastData = entityLastData[eid]
		if lastData == grid.data then
			continue
		end
		entityLastData[eid] = grid.data

		local serverEid = replecsClient and replecsClient:get_server_entity(eid) or eid
		local renderable = world:get(eid, Components.Renderable)
		local sourcePart = renderable and renderable.instance :: BasePart?
		rebuildMesh(eid, serverEid, grid, sourcePart)
	end

	for eid, parts in entityMeshParts do
		if not world:contains(eid) or not world:get(eid, Components.VoxelGrid) then
			for _, part in parts do
				part:Destroy()
			end
			entityMeshParts[eid] = nil
			entityLastData[eid] = nil

			if world:contains(eid) then
				local renderable = world:get(eid, Components.Renderable)
				restoreSourcePart(renderable and renderable.instance :: BasePart?)
			end
		end
	end
end

return voxelMeshesAreRendered
