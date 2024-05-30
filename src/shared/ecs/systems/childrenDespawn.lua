local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Components = require(ReplicatedStorage.ecs.components)
local Matter = require(ReplicatedStorage.packages.Matter)
local MatterTypes = require(ReplicatedStorage.ecs.MatterTypes)

type ChildrenRecord = MatterTypes.WorldChangeRecord<Components.Children>

local function childrenDespawn(world: Matter.World)
	for _eid, childrenRecord: ChildrenRecord in world:queryChanged(Components.Children) do
		if childrenRecord.new == nil and childrenRecord.old ~= nil then
			for _, childId in childrenRecord.old.children do
				if world:contains(childId) then
					world:despawn(childId)
				end
			end
		end
	end
end

return childrenDespawn
