local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Components = require(ReplicatedStorage.ecs.components)
local Matter = require(ReplicatedStorage.packages.Matter)
local MatterTypes = require(ReplicatedStorage.ecs.MatterTypes)

type ChildrenRecord = MatterTypes.WorldChangeRecord<Components.Children<any>>
type ParentRecord = MatterTypes.WorldChangeRecord<Components.Parent>

local function childrenDespawn(world: Matter.World)
	for _eid, childrenRecord: ChildrenRecord in world:queryChanged(Components.Children) do
		if childrenRecord.new == nil and childrenRecord.old ~= nil then
			for _key, childId in childrenRecord.old.children do
				if world:contains(childId) then
					world:despawn(childId)
				end
			end
		elseif childrenRecord.new and childrenRecord.old then
			for key, childId in childrenRecord.old.children do
				if not childrenRecord.new.children[key] then
					if world:contains(childId) then
						world:despawn(childId)
					end
				end
			end
		end
	end

	for eid, parentRecord: ParentRecord in world:queryChanged(Components.Parent) do -- handle children despawning and removing them from parent's children list
		if parentRecord.new == nil and parentRecord.old then
			local parent = parentRecord.old.id

			if not world:contains(parent) then
				continue -- parent was despawned, not just a child change
			end

			local parentChildren: Components.Children<any>? = world:get(parent, Components.Children)
			if parentChildren then
				local newChildren = table.clone(parentChildren.children)
				for key, childId in newChildren do
					if childId == eid then
						newChildren[key] = nil
					end
				end
				world:insert(
					parent,
					parentChildren:patch({
						children = newChildren,
					})
				)
			end
		end
	end
end

return childrenDespawn
