--!strict

-- Greedy 3D box merging: converts a packed-bit VoxelGrid into a minimal set of boxes.
-- Each box is { min = Vector3, max = Vector3 } in integer grid-cell coordinates.

local VoxelBuffer = require("@utilities/VoxelBuffer")

export type Box = { min: Vector3, max: Vector3 }

local function greedyMerge(data: buffer, sizeX: number, sizeY: number, sizeZ: number): { Box }
	local visited = buffer.create(math.ceil(sizeX * sizeY * sizeZ / 8))
	local boxes: { Box } = {}

	for z = 0, sizeZ - 1 do
		for y = 0, sizeY - 1 do
			for x = 0, sizeX - 1 do
				local idx = VoxelBuffer.flatIndex(x, y, z, sizeX, sizeY)
				if not VoxelBuffer.get(data, idx) or VoxelBuffer.get(visited, idx) then
					continue
				end

				local maxX = x
				while maxX + 1 < sizeX do
					local nIdx = VoxelBuffer.flatIndex(maxX + 1, y, z, sizeX, sizeY)
					if not VoxelBuffer.get(data, nIdx) or VoxelBuffer.get(visited, nIdx) then
						break
					end
					maxX += 1
				end

				local maxY = y
				while maxY + 1 < sizeY do
					local valid = true
					for ix = x, maxX do
						local nIdx = VoxelBuffer.flatIndex(ix, maxY + 1, z, sizeX, sizeY)
						if not VoxelBuffer.get(data, nIdx) or VoxelBuffer.get(visited, nIdx) then
							valid = false
							break
						end
					end
					if not valid then
						break
					end
					maxY += 1
				end

				local maxZ = z
				while maxZ + 1 < sizeZ do
					local valid = true
					for iy = y, maxY do
						for ix = x, maxX do
							local nIdx = VoxelBuffer.flatIndex(ix, iy, maxZ + 1, sizeX, sizeY)
							if not VoxelBuffer.get(data, nIdx) or VoxelBuffer.get(visited, nIdx) then
								valid = false
								break
							end
						end
						if not valid then
							break
						end
					end
					if not valid then
						break
					end
					maxZ += 1
				end

				for iz = z, maxZ do
					for iy = y, maxY do
						for ix = x, maxX do
							VoxelBuffer.set(visited, VoxelBuffer.flatIndex(ix, iy, iz, sizeX, sizeY), true)
						end
					end
				end

				table.insert(boxes, {
					min = Vector3.new(x, y, z),
					max = Vector3.new(maxX, maxY, maxZ),
				})
			end
		end
	end

	return boxes
end

return greedyMerge
