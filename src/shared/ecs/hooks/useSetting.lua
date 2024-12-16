--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Controllers = LocalPlayer.PlayerScripts.controllers

local Matter = require(ReplicatedStorage.packages.Matter)
local SettingsController = require(Controllers.SettingsController)

local function cleanup(storage)
	if storage.connections then
		for _, connection in storage.connections do
			connection:Disconnect()
		end
	end
	if storage.collection then
		table.clear(storage.collection)
	end
end

local function useSetting(settingName: string): () -> any
	local storage = Matter.useHookState(settingName, cleanup) :: any

	if not storage.collection then
		storage.collection = {}
	end

	if not storage.connections then
		storage.connections = {}

		storage.connections.settingChanged = SettingsController:ObserveSettingsChanged(function(settings, oldSettings)
			if not oldSettings or settings[settingName] ~= oldSettings[settingName] then
				table.insert(storage.collection, settings[settingName])
			end
		end)
	end

	return function()
		local currIndex = storage.currIndex or 1
		storage.currIndex = currIndex + 1

		local value = storage.collection[currIndex]
		if not value then
			storage.currIndex = 1
			return nil
		end

		table.remove(storage.collection, currIndex)

		return value
	end
end

return useSetting
