--!strict

-- Server-authoritative voxel mesh + falling-section management.
--
-- Each voxel entity owns a set of greedy-meshed BasePart members in workspace.
-- Members carry the `voxelEntityId` attribute so client raycasts resolve them
-- back to the entity. Members are real server-replicated parts: clients see
-- them via Roblox's normal instance replication, no client-side mesh code.
--
-- When the cascade in VoxelHit decides a group of new entities should fall as
-- one, formSection runs a DFS over their members (probing axis-aligned
-- neighbors with a small epsilon overlap) and welds every connected component
-- to a single invisible "section anchor" part. The members are then unanchored
-- and Roblox simulates the rigid assembly server-side.

local jecs = require("@packages/jecs")

local Components = require("@ecs/components")
local GreedyMesh = require("@utilities/GreedyMesh")

local COLLISION_GROUP_MEMBER = "VoxelMesh"

-- Slight overlap on each axis so adjacent voxels (and parts with sub-stud
-- gaps) get welded together when forming a falling section.
local EPSILON = 0.05
local DFSWELD_X = Vector3.new(1 + EPSILON, 1 - EPSILON, 1 - EPSILON)
local DFSWELD_Y = Vector3.new(1 - EPSILON, 1 + EPSILON, 1 - EPSILON)
local DFSWELD_Z = Vector3.new(1 - EPSILON, 1 - EPSILON, 1 + EPSILON)

type MemberInfo = { cframe: CFrame, size: Vector3 }
type SectionState = {
	members: { [BasePart]: true },
	entities: { [number]: true },
	-- Tracked welds (parented to the welded part, but kept here so we can
	-- destroy them deterministically when reforming a section).
	welds: { [BasePart]: Weld },
}

local VoxelManager = {}

local entityMembers: { [number]: { [BasePart]: MemberInfo } } = {}
local entityLastData: { [number]: buffer } = {}
local entitySourceHidden: { [number]: true } = {}
local entitySectionAnchor: { [number]: BasePart } = {}
local sectionData: { [BasePart]: SectionState } = {}

local function hideSource(sourcePart: BasePart)
	sourcePart.Transparency = 1
	sourcePart.CanCollide = false
	sourcePart.CanQuery = false
	sourcePart.CastShadow = false

	for _, child in sourcePart:GetChildren() do
		if child:IsA("Decal") or child:IsA("Texture") then
			(child :: Decal).Transparency = 1
		elseif child:IsA("SurfaceGui") then
			(child :: SurfaceGui).Enabled = false
		end
	end
end

local function weldTogether(part: BasePart, anchor: BasePart, state: SectionState?)
	-- Real Weld (not WeldConstraint) so the assembly is rigid and Roblox
	-- treats it as a single physics body for ownership and replication.
	-- Parented to `part` so it dies with the part.
	local weld = Instance.new("Weld")
	weld.Part0 = anchor
	weld.Part1 = part
	weld.C0 = anchor.CFrame:ToObjectSpace(part.CFrame)
	weld.Parent = part
	part.Anchored = false
	-- Marker for updateTransforms: anything in a welded voxel assembly
	-- gets its CFrame from Roblox's physics replication, never from our
	-- ECS Transform component (which would PivotTo and break the assembly).
	part:SetAttribute("voxelSectionMember", true)
	if state then
		state.welds[part] = weld
	end
end

local function destroyMember(eid: number, member: BasePart)
	local members = entityMembers[eid]
	if members then
		members[member] = nil
	end

	local anchor = entitySectionAnchor[eid]
	if anchor then
		local section = sectionData[anchor]
		if section then
			section.members[member] = nil
			-- Weld is parented to the member and will be destroyed with it,
			-- but drop our tracked reference so reformSection's iteration is
			-- accurate.
			section.welds[member] = nil
		end
	end

	member:Destroy()
end

local function createMember(
	eid: number,
	cframe: CFrame,
	size: Vector3,
	color: Color3,
	material: Enum.Material
): BasePart
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = true
	part.CanQuery = true
	part.CanTouch = false
	part.CollisionGroup = COLLISION_GROUP_MEMBER
	part.Color = color
	part.Material = material
	part.Size = size
	part.CFrame = cframe
	part:SetAttribute("voxelEntityId", eid)
	part.Parent = workspace

	local members = entityMembers[eid] or {}
	members[part] = { cframe = cframe, size = size }
	entityMembers[eid] = members

	-- If the entity is already part of a falling section, glue this new
	-- member to the section anchor and unanchor it so it falls with the rest.
	local anchor = entitySectionAnchor[eid]
	if anchor and sectionData[anchor] then
		weldTogether(part, anchor, sectionData[anchor])
		sectionData[anchor].members[part] = true
	end

	return part
end

-- Re-greedy-mesh an entity's grid and diff-update its member parts.
-- Members whose cframe+size match an existing part are preserved; only changed
-- regions are torn down and rebuilt, so falling sections don't lose their
-- welds when an unrelated cell elsewhere is destroyed.
function VoxelManager.refreshEntity(eid: number, grid: Components.VoxelGrid, sourcePart: BasePart)
	local existing = entityMembers[eid] or {}

	local boxes = GreedyMesh(grid.data, grid.sizeX, grid.sizeY, grid.sizeZ)

	-- Origin from sourcePart so falling sections re-mesh at their CURRENT
	-- pose (the source is welded to the section anchor and tracks it).
	local originCFrame = sourcePart.CFrame
	local color = sourcePart.Color
	local material = sourcePart.Material

	local gridTotalSize = Vector3.new(grid.sizeX, grid.sizeY, grid.sizeZ) * grid.cellSize
	local halfGrid = gridTotalSize * 0.5
	local sourceSize = sourcePart.Size
	local maxInset = grid.cellSize * 0.5
	local outerInset = Vector3.new(
		math.clamp((gridTotalSize.X - sourceSize.X) * 0.5, 0, maxInset),
		math.clamp((gridTotalSize.Y - sourceSize.Y) * 0.5, 0, maxInset),
		math.clamp((gridTotalSize.Z - sourceSize.Z) * 0.5, 0, maxInset)
	)

	local maxX = grid.sizeX - 1
	local maxY = grid.sizeY - 1
	local maxZ = grid.sizeZ - 1

	type DesiredBox = { cframe: CFrame, size: Vector3 }
	local desiredBoxes: { DesiredBox } = {}

	for _, box in boxes do
		local boxMin = box.min * grid.cellSize - halfGrid
		local boxMax = (box.max + Vector3.one) * grid.cellSize - halfGrid

		if box.min.X == 0 then
			boxMin = boxMin + Vector3.new(outerInset.X, 0, 0)
		end
		if box.max.X == maxX then
			boxMax = boxMax - Vector3.new(outerInset.X, 0, 0)
		end
		if box.min.Y == 0 then
			boxMin = boxMin + Vector3.new(0, outerInset.Y, 0)
		end
		if box.max.Y == maxY then
			boxMax = boxMax - Vector3.new(0, outerInset.Y, 0)
		end
		if box.min.Z == 0 then
			boxMin = boxMin + Vector3.new(0, 0, outerInset.Z)
		end
		if box.max.Z == maxZ then
			boxMax = boxMax - Vector3.new(0, 0, outerInset.Z)
		end

		local center = (boxMin + boxMax) * 0.5
		local size = boxMax - boxMin
		table.insert(desiredBoxes, { cframe = originCFrame * CFrame.new(center), size = size })
	end

	local matched: { [BasePart]: true } = {}
	local toCreate: { DesiredBox } = {}

	for _, desired in desiredBoxes do
		local found: BasePart? = nil
		for part, info in existing do
			if matched[part] then
				continue
			end
			if info.size == desired.size and info.cframe.Position == desired.cframe.Position then
				found = part
				break
			end
		end
		if found then
			matched[found] = true
		else
			table.insert(toCreate, desired)
		end
	end

	for part in existing do
		if not matched[part] then
			destroyMember(eid, part)
		end
	end

	for _, desired in toCreate do
		createMember(eid, desired.cframe, desired.size, color, material)
	end

	if not entitySourceHidden[eid] then
		entitySourceHidden[eid] = true
		hideSource(sourcePart)
	end

	entityLastData[eid] = grid.data
end

-- Returns true if the entity is part of a falling section (its source has
-- been welded to a section anchor and unanchored).
function VoxelManager.isFalling(eid: number): boolean
	return entitySectionAnchor[eid] ~= nil
end

-- Returns the section anchor an entity currently belongs to, or nil.
function VoxelManager.getSectionAnchor(eid: number): BasePart?
	return entitySectionAnchor[eid]
end

-- Re-runs DFSWeld over the section's still-alive members. If the surviving
-- members are still one connected component, nothing changes. If destruction
-- has fragmented them, the old anchor is torn down and each component gets
-- its own new anchor — Shatterbox does the same after every operation that
-- modifies a falling group, otherwise pieces stay rigidly connected through
-- the invisible anchor even when there's nothing physical between them.
function VoxelManager.reformSection(world: any, oldAnchor: BasePart)
	local state = sectionData[oldAnchor]
	if not state then
		return
	end

	local aliveMembers: { [BasePart]: true } = {}
	for member in state.members do
		if member.Parent then
			aliveMembers[member] = true
		end
	end

	if not next(aliveMembers) then
		-- No members left at all: the section is done. Tear it down.
		for _, weld in state.welds do
			weld:Destroy()
		end
		oldAnchor:Destroy()
		sectionData[oldAnchor] = nil
		for eid in state.entities do
			if entitySectionAnchor[eid] == oldAnchor then
				entitySectionAnchor[eid] = nil
			end
		end
		return
	end

	local visited: { [BasePart]: true } = {}
	local components: { { BasePart } } = {}

	for startMember in aliveMembers do
		if visited[startMember] then
			continue
		end
		local comp: { BasePart } = {}
		local stack: { BasePart } = { startMember }
		visited[startMember] = true

		while #stack > 0 do
			local current = table.remove(stack) :: BasePart
			table.insert(comp, current)

			for _, axisOffset in { DFSWELD_X, DFSWELD_Y, DFSWELD_Z } do
				local touched =
					workspace:GetPartBoundsInBox(current.CFrame, current.Size * axisOffset)
				for _, neighbor in touched do
					if visited[neighbor] then
						continue
					end
					if not aliveMembers[neighbor] then
						continue
					end
					visited[neighbor] = true
					table.insert(stack, neighbor)
				end
			end
		end

		table.insert(components, comp)
	end

	if #components == 1 then
		-- Still one connected piece: nothing to do.
		return
	end

	-- Fragmented. Destroy every weld in the old section, drop the old anchor,
	-- and rebuild a fresh section per surviving component. All inside one
	-- synchronous pass so physics never ticks with parts mid-unweld.
	for _, weld in state.welds do
		weld:Destroy()
	end
	local oldEntities = state.entities
	oldAnchor:Destroy()
	sectionData[oldAnchor] = nil
	for eid in oldEntities do
		if entitySectionAnchor[eid] == oldAnchor then
			entitySectionAnchor[eid] = nil
		end
	end

	-- Map members back to their entities so each new sub-section knows which
	-- entities (and their source parts) it owns.
	for _, comp in components do
		local entitySet: { [number]: true } = {}
		local avgPos = Vector3.zero
		for _, member in comp do
			local memberEid = member:GetAttribute("voxelEntityId") :: number?
			if memberEid then
				entitySet[memberEid] = true
			end
			avgPos += member.Position
		end
		avgPos /= #comp

		local newAnchor = Instance.new("Part")
		newAnchor.Name = "VoxelSectionAnchor"
		newAnchor.Size = Vector3.one * 0.1
		newAnchor.Transparency = 1
		newAnchor.CanCollide = false
		newAnchor.CanQuery = false
		newAnchor.CanTouch = false
		newAnchor.CastShadow = false
		newAnchor.Massless = true
		newAnchor.Anchored = true
		newAnchor.CFrame = CFrame.new(avgPos)
		newAnchor.Parent = workspace

		local newState: SectionState = { members = {}, entities = entitySet, welds = {} }
		sectionData[newAnchor] = newState

		for _, member in comp do
			weldTogether(member, newAnchor, newState)
			newState.members[member] = true
		end

		for eid in entitySet do
			-- If an entity straddled the split (its members landed in
			-- multiple components), the first component to claim it wins;
			-- subsequent components get the members but not the source.
			if entitySectionAnchor[eid] then
				continue
			end
			entitySectionAnchor[eid] = newAnchor
			local renderable = world:get(eid, Components.Renderable)
			local sourcePart = renderable and renderable.instance :: BasePart?
			if sourcePart and sourcePart:IsA("BasePart") then
				weldTogether(sourcePart, newAnchor, newState)
			end
		end

		newAnchor:SetAttribute("voxelSectionMember", true)
		newAnchor.Anchored = false
		newAnchor:SetNetworkOwner(nil)
	end
end

-- Walks the union of `entities`' members via overlap probes, partitions them
-- into connected components, and welds each component to its own section
-- anchor. Each entity's source part is welded too so its CFrame tracks the
-- assembly's current pose (used as the origin for any future re-mesh).
function VoxelManager.formSection(world: any, entities: { [number]: true })
	local memberSet: { [BasePart]: number } = {}
	for eid in entities do
		local members = entityMembers[eid]
		if not members then
			continue
		end
		for member in members do
			memberSet[member] = eid
		end
	end

	if not next(memberSet) then
		return
	end

	local visited: { [BasePart]: true } = {}

	for startMember in memberSet do
		if visited[startMember] then
			continue
		end

		local section: { BasePart } = {}
		local sectionEntities: { [number]: true } = {}
		local stack: { BasePart } = { startMember }
		visited[startMember] = true

		while #stack > 0 do
			local current = table.remove(stack) :: BasePart
			table.insert(section, current)
			sectionEntities[memberSet[current]] = true

			for _, axisOffset in { DFSWELD_X, DFSWELD_Y, DFSWELD_Z } do
				local touched =
					workspace:GetPartBoundsInBox(current.CFrame, current.Size * axisOffset)
				for _, neighbor in touched do
					if visited[neighbor] then
						continue
					end
					if not memberSet[neighbor] then
						continue
					end
					visited[neighbor] = true
					table.insert(stack, neighbor)
				end
			end
		end

		if #section == 0 then
			continue
		end

		local avgPos = Vector3.zero
		for _, member in section do
			avgPos += member.Position
		end
		avgPos /= #section

		local anchor = Instance.new("Part")
		anchor.Name = "VoxelSectionAnchor"
		anchor.Size = Vector3.one * 0.1
		anchor.Transparency = 1
		anchor.CanCollide = false
		anchor.CanQuery = false
		anchor.CanTouch = false
		anchor.CastShadow = false
		anchor.Massless = true
		anchor.Anchored = true
		anchor.CFrame = CFrame.new(avgPos)
		anchor.Parent = workspace

		local state: SectionState = { members = {}, entities = sectionEntities, welds = {} }
		sectionData[anchor] = state

		for _, member in section do
			weldTogether(member, anchor, state)
			state.members[member] = true
		end

		for eid in sectionEntities do
			entitySectionAnchor[eid] = anchor
			local renderable = world:get(eid, Components.Renderable)
			local sourcePart = renderable and renderable.instance :: BasePart?
			if sourcePart and sourcePart:IsA("BasePart") then
				-- Massless so the source's volume doesn't dominate the
				-- assembly's center of mass; mass comes from real members.
				sourcePart.Massless = true
				weldTogether(sourcePart, anchor, state)
			end
		end

		anchor:SetAttribute("voxelSectionMember", true)
		anchor.Anchored = false
		anchor:SetNetworkOwner(nil)
	end
end

-- Called from the VoxelGrid OnRemove hook. Tears down members and (if the
-- entity was alone in a section) the section anchor.
function VoxelManager.cleanupEntity(eid: number)
	local members = entityMembers[eid]
	if members then
		for member in members do
			member:Destroy()
		end
		entityMembers[eid] = nil
	end

	local anchor = entitySectionAnchor[eid]
	if anchor then
		local state = sectionData[anchor]
		if state then
			state.entities[eid] = nil
			-- Sweep dead member/weld references for this entity's parts.
			for member in state.members do
				if not member:IsDescendantOf(workspace) then
					state.members[member] = nil
					state.welds[member] = nil
				end
			end
			if not next(state.entities) and not next(state.members) then
				for _, weld in state.welds do
					weld:Destroy()
				end
				anchor:Destroy()
				sectionData[anchor] = nil
			end
		end
		entitySectionAnchor[eid] = nil
	end

	entityLastData[eid] = nil
	entitySourceHidden[eid] = nil
end

function VoxelManager.getLastData(eid: number): buffer?
	return entityLastData[eid]
end

return VoxelManager
