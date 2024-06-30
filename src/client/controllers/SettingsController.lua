--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerScripts = LocalPlayer.PlayerScripts
local Packages = ReplicatedStorage.packages

local ClientComm = require(PlayerScripts.ClientComm)
local Settings = require(ReplicatedStorage.constants.Settings)
local Signal = require(Packages.Signal)
local Types = require(ReplicatedStorage.constants.Types)

local PlayerSettingsProperty = ClientComm:GetProperty("PlayerSettings")

local SettingsController = {
	Name = "SettingsController",
	Settings = {},
	Categories = {
		{
			Name = "General",
			Description = "Core settings for the game.",
		},
		{
			Name = "Graphics",
			Description = "Graphics settings for the game.",
		},
		{
			Name = "Audio",
			Description = "Audio settings for the game.",
		},
		{
			Name = "Gameplay",
			Description = "Gameplay settings for the game.",
		},
		{
			Name = "Keybinds",
			Description = "Keybind settings for the game.",
		},
		{
			Name = "Extra",
			Description = "Extra settings for the game.",
		},
	},
	SettingsChanged = Signal.new() :: Signal.Signal<Types.PlayerDataSettings>,
}

-- // Functions \\

function SettingsController:Init()
	PlayerSettingsProperty:Observe(function(playerSettings: Types.PlayerDataSettings?)
		if playerSettings then
			SettingsController.SettingsChanged:Fire(playerSettings)
		end
	end)
end

function SettingsController:GetReplicatedSettings()
	return PlayerSettingsProperty:Get()
end

function SettingsController:ObserveSettingsChanged(callback: (Types.PlayerDataSettings) -> ())
	local playerSettings = PlayerSettingsProperty:Get()
	if playerSettings then
		callback(playerSettings)
	end
	return SettingsController.SettingsChanged:Connect(callback)
end

function SettingsController:FillInSettings(playerSettings: Types.PlayerDataSettings): Types.PlayerDataSettings
	local fullSettings = {}
	for settingName, setting in Settings do
		if playerSettings[settingName] then
			fullSettings[settingName] = playerSettings[settingName]
		else
			fullSettings[settingName] = {
				Value = setting.Default,
			}
		end
	end
	return fullSettings
end

function SettingsController:BuildSettingProps(settingName: string, settingInternal: Types.SettingInternal): any
	local settingInfo = Settings[settingName]
	if settingInfo.Type == "Slider" then
		return {
			minimum = settingInfo.Minimum,
			maximum = settingInfo.Maximum,
			percentage = settingInternal.Value,
			increment = settingInfo.Increment,
		}
	elseif settingInfo.Type == "Toggle" then
		return {
			buttonType = "Secondary",
			toggled = settingInternal.Value,
		}
	elseif settingInfo.Type == "Input" then
		return {
			currentInput = settingInternal.Value,
			inputVerifiers = settingInfo.InputVerifiers,
			inputRange = { 0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1 },
			outputRange = { 0, -15, 15, -15, 15, -15, 15, -15, 15, -15, 0 },
		}
	elseif settingInfo.Type == "Keybind" then
		return {
			keybindMap = settingInternal.Value,
		}
	elseif settingInfo.Type == "Dropdown" then
		return {
			currentSelection = settingInternal.Value,
			selections = settingInfo.Selections,
		}
	else
		return {}
	end
end

return SettingsController
