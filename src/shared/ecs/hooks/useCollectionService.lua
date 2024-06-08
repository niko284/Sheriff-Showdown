local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Matter = require(ReplicatedStorage.packages.Matter)

local function cleanup(storage)
	if storage.connections then
		for _, connection in storage.connections do
			connection:Disconnect()
		end
	end
	table.clear(storage.collection)
end

local function useCollectionService(tag: string)
	local storage = Matter.useHookState({
		collection = CollectionService:GetTagged(tag),
		currIndex = 1,
	}, cleanup)

	if not storage.connections then
		storage.connections = {}

		storage.connections.onAdded = CollectionService:GetInstanceAddedSignal(tag):Connect(function(instance: Instance)
			table.insert(storage.collection, instance)
		end)
		storage.connections.onRemoved = CollectionService:GetInstanceRemovedSignal(tag)
			:Connect(function(instance: Instance)
				local index = table.find(storage.collection, instance)
				if index then
					table.remove(storage.collection, index)
				end
			end)
	end

	return function()
		local currIndex = storage.currIndex
		storage.currIndex = currIndex + 1

		local value = storage.collection[currIndex]
		if not value then
			storage.currIndex = 1
			return nil
		end

		return value
	end
end

return useCollectionService
