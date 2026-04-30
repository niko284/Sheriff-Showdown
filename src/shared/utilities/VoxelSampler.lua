--!strict

local AssetService = game:GetService("AssetService")

local VoxelBuffer = require("@utilities/VoxelBuffer")

local VoxelSampler = {}

-- SAT helpers — all in AABB-local space (AABB centered at origin).

local function separatesOnAxis(axis: Vector3, v0: Vector3, v1: Vector3, v2: Vector3, half: Vector3): boolean
	local p0, p1, p2 = axis:Dot(v0), axis:Dot(v1), axis:Dot(v2)
	local r = math.abs(axis.X) * half.X + math.abs(axis.Y) * half.Y + math.abs(axis.Z) * half.Z
	return math.min(p0, p1, p2) > r or math.max(p0, p1, p2) < -r
end

local function triangleOverlapsAABB(v0: Vector3, v1: Vector3, v2: Vector3, center: Vector3, half: Vector3): boolean
	local a, b, c = v0 - center, v1 - center, v2 - center
	local e0, e1, e2 = b - a, c - b, a - c

	local axes = {
		Vector3.new(1, 0, 0),
		Vector3.new(0, 1, 0),
		Vector3.new(0, 0, 1),
		e0:Cross(e1),
		Vector3.new(0, -e0.Z, e0.Y),
		Vector3.new(0, -e1.Z, e1.Y),
		Vector3.new(0, -e2.Z, e2.Y),
		Vector3.new(e0.Z, 0, -e0.X),
		Vector3.new(e1.Z, 0, -e1.X),
		Vector3.new(e2.Z, 0, -e2.X),
		Vector3.new(-e0.Y, e0.X, 0),
		Vector3.new(-e1.Y, e1.X, 0),
		Vector3.new(-e2.Y, e2.X, 0),
	}

	for _, axis in axes do
		if axis.Magnitude < 1e-6 then
			continue
		end
		if separatesOnAxis(axis, a, b, c, half) then
			return false
		end
	end

	return true
end

local FLOOD_NEIGHBORS: { { number } } = {
	{ 1, 0, 0 },
	{ -1, 0, 0 },
	{ 0, 1, 0 },
	{ 0, -1, 0 },
	{ 0, 0, 1 },
	{ 0, 0, -1 },
}

-- BFS flood fill from all exterior empty boundary cells.
-- Empty cells not reachable from boundary are interior → marked solid in the returned buffer.
local function floodFillInterior(data: buffer, sizeX: number, sizeY: number, sizeZ: number): buffer
	local visited = buffer.create(math.ceil(sizeX * sizeY * sizeZ / 8))
	local queue: { number } = {}

	for z = 0, sizeZ - 1 do
		for y = 0, sizeY - 1 do
			for x = 0, sizeX - 1 do
				local isBoundary = x == 0 or x == sizeX - 1 or y == 0 or y == sizeY - 1 or z == 0 or z == sizeZ - 1
				if not isBoundary then
					continue
				end
				local idx = VoxelBuffer.flatIndex(x, y, z, sizeX, sizeY)
				if not VoxelBuffer.get(data, idx) and not VoxelBuffer.get(visited, idx) then
					VoxelBuffer.set(visited, idx, true)
					table.insert(queue, idx)
				end
			end
		end
	end

	local sliceSize = sizeX * sizeY
	local head = 1
	while head <= #queue do
		local idx = queue[head]
		head += 1

		local iz = math.floor(idx / sliceSize)
		local rem = idx % sliceSize
		local iy = math.floor(rem / sizeX)
		local ix = rem % sizeX

		for _, off in FLOOD_NEIGHBORS do
			local nx = ix + off[1]
			local ny = iy + off[2]
			local nz = iz + off[3]
			if nx < 0 or nx >= sizeX or ny < 0 or ny >= sizeY or nz < 0 or nz >= sizeZ then
				continue
			end
			local nIdx = VoxelBuffer.flatIndex(nx, ny, nz, sizeX, sizeY)
			if not VoxelBuffer.get(data, nIdx) and not VoxelBuffer.get(visited, nIdx) then
				VoxelBuffer.set(visited, nIdx, true)
				table.insert(queue, nIdx)
			end
		end
	end

	local result = VoxelBuffer.clone(data)
	for z = 0, sizeZ - 1 do
		for y = 0, sizeY - 1 do
			for x = 0, sizeX - 1 do
				local idx = VoxelBuffer.flatIndex(x, y, z, sizeX, sizeY)
				if not VoxelBuffer.get(data, idx) and not VoxelBuffer.get(visited, idx) then
					VoxelBuffer.set(result, idx, true)
				end
			end
		end
	end

	return result
end

function VoxelSampler.voxelizeBasePart(part: BasePart, cellSize: number): (buffer, number, number, number)
	local size = part.Size
	local sX = math.max(1, math.round(size.X / cellSize))
	local sY = math.max(1, math.round(size.Y / cellSize))
	local sZ = math.max(1, math.round(size.Z / cellSize))
	return VoxelBuffer.new(sX, sY, sZ), sX, sY, sZ
end

function VoxelSampler.voxelizeMeshPart(meshPart: MeshPart, cellSize: number): (buffer, number, number, number)
	local size = meshPart.Size
	local sX = math.max(1, math.round(size.X / cellSize))
	local sY = math.max(1, math.round(size.Y / cellSize))
	local sZ = math.max(1, math.round(size.Z / cellSize))

	local ok, editableMesh = pcall(AssetService.CreateEditableMeshFromPartAsync, AssetService, meshPart)
	if not ok or not editableMesh then
		return VoxelSampler.voxelizeBasePart(meshPart, cellSize)
	end

	local data = buffer.create(math.ceil(sX * sY * sZ / 8))
	local half = Vector3.one * (cellSize * 0.5)

	local faces = editableMesh:GetFaces()
	for _, faceId in faces do
		local v0Id, v1Id, v2Id = editableMesh:GetFaceVertices(faceId)
		local v0 = editableMesh:GetPosition(v0Id)
		local v1 = editableMesh:GetPosition(v1Id)
		local v2 = editableMesh:GetPosition(v2Id)

		local triMin = v0:Min(v1):Min(v2) + size * 0.5
		local triMax = v0:Max(v1):Max(v2) + size * 0.5

		local x0 = math.max(0, math.floor(triMin.X / cellSize))
		local y0 = math.max(0, math.floor(triMin.Y / cellSize))
		local z0 = math.max(0, math.floor(triMin.Z / cellSize))
		local x1 = math.min(sX - 1, math.floor(triMax.X / cellSize))
		local y1 = math.min(sY - 1, math.floor(triMax.Y / cellSize))
		local z1 = math.min(sZ - 1, math.floor(triMax.Z / cellSize))

		for z = z0, z1 do
			for y = y0, y1 do
				for x = x0, x1 do
					local idx = VoxelBuffer.flatIndex(x, y, z, sX, sY)
					if VoxelBuffer.get(data, idx) then
						continue
					end
					local cellCenter = Vector3.new(
						(x + 0.5) * cellSize - size.X * 0.5,
						(y + 0.5) * cellSize - size.Y * 0.5,
						(z + 0.5) * cellSize - size.Z * 0.5
					)
					if triangleOverlapsAABB(v0, v1, v2, cellCenter, half) then
						VoxelBuffer.set(data, idx, true)
					end
				end
			end
		end
	end

	editableMesh:Destroy()
	data = floodFillInterior(data, sX, sY, sZ)

	return data, sX, sY, sZ
end

return VoxelSampler
