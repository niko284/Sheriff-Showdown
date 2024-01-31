--!strict

-- Settings Service
-- March 6th, 2022
-- Nick

-- // Variables \\

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Services = ServerScriptService.services
local Constants = ReplicatedStorage.constants
local Packages = ReplicatedStorage.packages
local SettingsFolder = ReplicatedStorage.Settings

local DataService = require(Services.DataService)
local Remotes = require(ReplicatedStorage.Remotes)
local ServerComm = require(ServerScriptService.ServerComm)
local Signal = require(Packages.Signal)
local Types = require(Constants.Types)
local t = require(Packages.t)

local SettingsRemotes = Remotes.Server:GetNamespace("Settings")
local ChangeSetting = SettingsRemotes:Get("ChangeSetting")

local SettingTypes = {
	Toggle = t.boolean,
	Slider = t.numberConstrained(0, 100),
	Dropdown = t.string,
	List = t.map(t.string, t.boolean),
}

-- // Service Variables \\

local SettingsService = {
	Name = "SettingsService",
	PlayerSettings = ServerComm:CreateProperty("PlayerSettings", {}),
	SettingsTemplate = {},
	Settings = {},
	SettingChanged = Signal.new() :: Signal.Signal<Player, string, Types.SettingValue>,
}

-- // Functions \\

function SettingsService:Init()
	for _, SettingModule: Instance in SettingsFolder.Options:GetChildren() do
		if SettingModule:IsA("ModuleScript") then
			local Setting = require(SettingModule) :: any
			self.Settings[Setting.Name] = Setting
		end
	end
	DataService.PlayerDataLoaded:Connect(function(Player: Player, Profile: any)
		self.PlayerSettings:SetFor(Player, Profile.Data.Settings)
	end)
	ChangeSetting:SetCallback(function(Player: Player, SettingName: string, Value: Types.SettingValue)
		return self:ChangeSettingRequest(Player, SettingName, Value)
	end)
end

function SettingsService:GetSettings(Player: Player): Types.PlayerDataSettings?
	local playerProfile = DataService:GetData(Player)
	if playerProfile then
		return playerProfile.Data.Settings
	end
	return nil
end

function SettingsService:IsValidValue(Setting: Types.Setting, Value: any): boolean
	local typeCheck = SettingTypes[Setting.Type]
	if typeCheck and typeCheck(Value) then
		if Setting.Type == "Dropdown" and Setting.Selections then -- Verify that the selection is valid
			for _, selection in Setting.Selections do
				if selection == Value then
					return true
				end
			end
			return false
		elseif Setting.Type == "List" and Setting.Choices then -- Verify that all choices are valid
			for choice, _ in Value do
				if not table.find(Setting.Choices, choice) then
					return false
				end
			end
		end
		return true
	end
	return false
end

function SettingsService:ChangeSettingRequest(Player: Player, SettingName: string, Value: Types.SettingValue)
	local Setting = self.Settings[SettingName]
	local PlayerData = DataService:GetData(Player)
	if Setting and PlayerData then
		if self:IsValidValue(Setting, Value) and Setting.Type ~= "Keybind" then
			PlayerData.Data.Settings[SettingName] = {
				Value = Value,
			}
			SettingsService.SettingChanged:Fire(Player, SettingName, Value)
			return {
				Success = true,
				Response = "Setting changed successfully",
			}
		end
	end
	return {
		Success = false,
		Response = "Invalid setting or value",
	}
end

return SettingsService
