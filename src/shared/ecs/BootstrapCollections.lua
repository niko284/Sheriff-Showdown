--!strict

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Components = require(ReplicatedStorage.ecs.components)
local Matter = require(ReplicatedStorage.packages.Matter)
local MatterTypes = require(ReplicatedStorage.ecs.MatterTypes)

local idAttribute = RunService:IsServer() and "serverEntityId" or "clientEntityId"

local function bootstrapCollections(
	world: Matter.World,
	collections: { [string]: { MatterTypes.Component<any> } },
	descendantsOf: { Instance }?
)
	local function isDescendantOf(instance: Instance): boolean
		if descendantsOf == nil then
			return true
		end

		for _, parent in ipairs(descendantsOf) do
			if instance:IsDescendantOf(parent) then
				return true
			end
		end

		return false
	end

	local function spawnInstance(instance: Instance, tag: string)
		local componentInstances = {}
		for _, component in collections[tag] do
			table.insert(componentInstances, component({}))
		end

		local currCFrame = instance:IsA("PVInstance") and instance:GetPivot() or CFrame.new()

		table.insert(componentInstances, Components.Renderable({ instance = instance }))
		table.insert(componentInstances, Components.Transform({ cframe = currCFrame }))

		world:spawn(unpack(componentInstances))
	end

	-- get pre-defined collections
	for tag, _ in collections do
		local collection = CollectionService:GetTagged(tag)
		for _, instance in collection do
			if isDescendantOf(instance) then
				spawnInstance(instance, tag)
			end
		end
	end

	-- listen for new and removed instances in collections
	for tag, _ in collections do
		CollectionService:GetInstanceAddedSignal(tag):Connect(function(instance: Instance)
			if isDescendantOf(instance) then
				spawnInstance(instance, tag)
			end
		end)
		CollectionService:GetInstanceRemovedSignal(tag):Connect(function(instance: Instance)
			local entityId = instance:GetAttribute(idAttribute)
			if world:contains(entityId) then
				world:despawn(entityId)
			end
		end)
	end
end

return bootstrapCollections
