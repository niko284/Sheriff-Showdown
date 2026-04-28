--!strict

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local jecs = require("@packages/jecs")

local Components = require("@ecs/components")

local idAttribute = if RunService:IsServer() then "serverEntityId" else "clientEntityId"

local function bootstrapCollections(
	world: jecs.World,
	collections: { [string]: { any } },
	descendantsOf: { Instance }?,
	onSpawn: ((jecs.Entity, string) -> ())?
)
	local function isDescendantOf(instance: Instance): boolean
		if descendantsOf == nil then
			return true
		end
		for _, parent in descendantsOf do
			if instance:IsDescendantOf(parent) then
				return true
			end
		end
		return false
	end

	local instanceToEntity: { [Instance]: jecs.Entity } = {}

	local function spawnInstance(instance: Instance, tag: string)
		local eid = world:entity()
		for _, entry in collections[tag] do
			if type(entry) == "table" then
				world:set(eid, entry[1], entry[2])
			else
				world:add(eid, entry)
			end
		end

		local cframe = if instance:IsA("PVInstance") then instance:GetPivot() else CFrame.new()

		world:set(eid, Components.Renderable, { instance = instance })
		world:set(eid, Components.Transform, { cframe = cframe })

		instance:SetAttribute(idAttribute, eid)
		instanceToEntity[instance] = eid

		if onSpawn then
			onSpawn(eid, tag)
		end
	end

	for tag, _ in collections do
		for _, instance in CollectionService:GetTagged(tag) do
			if isDescendantOf(instance) then
				spawnInstance(instance, tag)
			end
		end
	end

	for tag, _ in collections do
		CollectionService:GetInstanceAddedSignal(tag):Connect(function(instance: Instance)
			if isDescendantOf(instance) then
				spawnInstance(instance, tag)
			end
		end)
		CollectionService:GetInstanceRemovedSignal(tag):Connect(function(instance: Instance)
			local eid = instanceToEntity[instance]
			if eid and world:contains(eid) then
				world:delete(eid)
			end
			instanceToEntity[instance] = nil
		end)
	end
end

return bootstrapCollections
