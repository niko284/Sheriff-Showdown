-- Settings Controller
-- February 24th, 2022
-- Nick

-- // Variables \\

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerScripts = LocalPlayer.PlayerScripts
local Packages = ReplicatedStorage.packages
local Slices = PlayerScripts.rodux.slices

local ClientComm = require(PlayerScripts.ClientComm)
local Signal = require(Packages.Signal)

local Settings = ReplicatedStorage.Settings
local PlayerSettingsProperty = ClientComm:GetProperty("PlayerSettings")

-- // Controller Variables \\

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
}

-- // Functions \\

function SettingsController:Init()
	self.Store = require(PlayerScripts.rodux.Store)
	self.SettingsSlice = require(Slices.SettingsSlice) :: any
	for _, Category in self.Categories do
		Category.SettingChanged = Signal.new() -- Signal for when a setting in the category changes
	end
	for _, SettingModule: Instance in Settings.Options:GetChildren() do
		if SettingModule:IsA("ModuleScript") then
			local Setting = require(SettingModule)
			self.Settings[Setting.Name] = Setting
		end
	end
	PlayerSettingsProperty:Observe(function(playerSettings)
		self.Store:dispatch(self.SettingsSlice.actions.SetSettings({ settings = playerSettings }))
	end)
end

function SettingsController:GetSettingsByCategories()
	local SettingsByCategory = {}
	for _, Setting in pairs(self.Settings) do
		if not SettingsByCategory[Setting.Category] and SettingsController:GetCategory(Setting.Category) then
			SettingsByCategory[Setting.Category] = {}
			SettingsByCategory[Setting.Category].Settings = {}
			SettingsByCategory[Setting.Category].Category = SettingsController:GetCategory(Setting.Category)
		end
		table.insert(SettingsByCategory[Setting.Category].Settings, Setting)
	end
	return SettingsByCategory
end

function SettingsController:GetCategory(CategoryName: string)
	for _, Category in pairs(self.Categories) do
		if Category.Name == CategoryName then
			return Category
		end
	end
	return nil
end

function SettingsController:GetSettingInformation(SettingName: string)
	return self.Settings[SettingName]
end

function SettingsController:ListenForCategoryChange(CategoryName: string, Callback)
	local categorySettings = self:GetSettingsByCategories()[CategoryName].Settings
	-- fire it initially when we call the function. this'll prevent race conditions particularly for listeners that initialize early in the game lifecycle.
	for _, Setting in categorySettings do
		local userSetting = self:GetSetting(Setting.Name)
		local value = nil
		if userSetting == "Default" then
			value = Setting.Default
		elseif userSetting then
			value = userSetting.Value
		end
		if userSetting then
			Callback(Setting.Name, value)
		end
	end
	return self:GetCategory(CategoryName).SettingChanged:Connect(Callback)
end

function SettingsController:GetSetting(SettingName: string)
	local settingState = self.Store:getState().Settings
	if not settingState and not settingState[SettingName] then
		return "Default"
	end
	return settingState[SettingName]
end

function SettingsController:GetAllSettingInformation()
	return self.Settings
end

return SettingsController
