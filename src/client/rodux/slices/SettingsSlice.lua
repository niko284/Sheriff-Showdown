-- Settings Slice
-- August 8th, 2023
-- Nick

-- // Variables \\

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.packages
local LocalPlayer = Players.LocalPlayer
local PlayerScripts = LocalPlayer.PlayerScripts
local Controllers = PlayerScripts.controllers

local Input = require(Packages.Input)
local RoduxUtils = require(Packages.RoduxUtils)
local SettingsController = require(Controllers.SettingsController)

local PreferredInput = Input.PreferredInput

-- // Slice \\

return RoduxUtils.createSlice({
	name = "Settings",
	initialState = {},
	reducers = {
		SetSettings = function(state, action)
			for _, setting in pairs(SettingsController.Settings) do
				if not action.payload.settings[setting.Name] and not state[setting.Name] then
					state[setting.Name] = "Default" -- Indicate the setting should use the default value
				elseif action.payload.settings[setting.Name] and not state[setting.Name] then
					state[setting.Name] = action.payload.settings[setting.Name]
				elseif action.payload.settings[setting.Name] and state[setting.Name] then
					local value = action.payload.settings[setting.Name].Value
					if setting.Type == "Keybind" then
						value = action.payload.settings[setting.Name][PreferredInput.Current].Value
					end
					if state[setting.Name].Value ~= value then
						state[setting.Name] = action.payload.settings[setting.Name]
					end
				end
			end
		end,
	},
})
