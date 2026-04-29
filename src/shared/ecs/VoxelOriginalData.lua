--!strict

-- Server-side store of each voxel entity's original buffer (snapshot at voxelization).
-- Used by VoxelHit to distinguish "this cell was always overhanging" from
-- "this cell lost its support due to damage" when computing loose voxels.

local store: { [number]: buffer } = {}

local VoxelOriginalData = {}

function VoxelOriginalData.set(eid: number, buf: buffer)
	store[eid] = buf
end

function VoxelOriginalData.get(eid: number): buffer?
	return store[eid]
end

function VoxelOriginalData.remove(eid: number)
	store[eid] = nil
end

return VoxelOriginalData
