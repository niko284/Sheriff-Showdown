--!strict

local VoxelBuffer = {}

function VoxelBuffer.new(sizeX: number, sizeY: number, sizeZ: number): buffer
	local totalBytes = math.ceil(sizeX * sizeY * sizeZ / 8)
	local buf = buffer.create(totalBytes)
	for i = 0, totalBytes - 1 do
		buffer.writeu8(buf, i, 0xFF)
	end
	return buf
end

function VoxelBuffer.get(buf: buffer, idx: number): boolean
	local byte = math.floor(idx / 8)
	local bit = idx % 8
	return bit32.band(buffer.readu8(buf, byte), bit32.lshift(1, bit)) ~= 0
end

function VoxelBuffer.set(buf: buffer, idx: number, value: boolean)
	local byte = math.floor(idx / 8)
	local bit = idx % 8
	local current = buffer.readu8(buf, byte)
	if value then
		buffer.writeu8(buf, byte, bit32.bor(current, bit32.lshift(1, bit)))
	else
		buffer.writeu8(buf, byte, bit32.band(current, bit32.bnot(bit32.lshift(1, bit))))
	end
end

function VoxelBuffer.flatIndex(x: number, y: number, z: number, sizeX: number, sizeY: number): number
	return x + y * sizeX + z * sizeX * sizeY
end

function VoxelBuffer.clearIndices(buf: buffer, indices: buffer)
	local count = math.floor(buffer.len(indices) / 4)
	for i = 0, count - 1 do
		VoxelBuffer.set(buf, buffer.readu32(indices, i * 4), false)
	end
end

function VoxelBuffer.clone(buf: buffer): buffer
	local size = buffer.len(buf)
	local newBuf = buffer.create(size)
	buffer.copy(newBuf, 0, buf)
	return newBuf
end

return VoxelBuffer
