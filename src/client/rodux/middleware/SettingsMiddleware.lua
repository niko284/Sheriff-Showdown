-- Settings Middleware
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
local SettingsController = require(Controllers.SettingsController)

local PreferredInput = Input.PreferredInput

-- // Middleware \\

return function(nextDispatch, store)
	return function(action)
		if action.type == "SetSettings" then
			local oldSettings = store:getState().Settings or {}
			local newSettings = action.payload.settings
			for _, setting in SettingsController.Settings do
				if not newSettings[setting.Name] and not oldSettings[setting.Name] then
					SettingsController:GetCategory(setting.Category).SettingChanged
						:Fire(setting.Name, setting.Default, newSettings)
				elseif newSettings[setting.Name] and not oldSettings[setting.Name] then
					local value = newSettings[setting.Name].Value
					if setting.Type == "Keybind" then
						local inputData = newSettings[setting.Name][PreferredInput.Current]
						if inputData then
							value = inputData.Value
						end
					end
					SettingsController:GetCategory(setting.Category).SettingChanged:Fire(setting.Name, value, newSettings)
				elseif newSettings[setting.Name] and oldSettings[setting.Name] then
					local value = newSettings[setting.Name].Value
					if setting.Type == "Keybind" then
						local inputData = newSettings[setting.Name][PreferredInput.Current]
						if inputData then
							value = inputData.Value
						end
					end
					if oldSettings[setting.Name].Value ~= value then
						SettingsController:GetCategory(setting.Category).SettingChanged
							:Fire(setting.Name, value, newSettings)
					end
				end
			end
		end
		return nextDispatch(action)
	end
end
