--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Services = ServerScriptService.services
local Constants = ReplicatedStorage.constants
local Packages = ReplicatedStorage.packages

local EnumUtils = require(ReplicatedStorage.utils.EnumUtils)
local Freeze = require(Packages.Freeze)
local Net = require(Packages.Net)
local PlayerDataService = require(Services.PlayerDataService)
local Remotes = require(ReplicatedStorage.network.Remotes)
local ServerComm = require(ServerScriptService.ServerComm)
local Settings = require(ReplicatedStorage.constants.Settings)
local Signal = require(Packages.Signal)
local Types = require(Constants.Types)
local t = require(Packages.t)

local SettingsRemotes = Remotes.Server:GetNamespace("Settings")
local ChangeSetting = SettingsRemotes:Get("ChangeSetting") :: Net.ServerAsyncCallback

local SettingTypes = {
	Toggle = t.boolean,
	Slider = t.numberConstrained(0, 100),
	Dropdown = t.string,
	List = t.map(t.string, t.boolean),
	Input = t.string,
	Keybind = t.map(t.string, t.string),
}

local AllowedDevices = { "MouseKeyboard", "Gamepad" }
local RestrictedKeybinds = { -- TODO: Add more keybinds. Table defines the keybinds that are restricted.
	W = true,
	A = true,
	S = true,
	D = true,
	KeypadEnter = true,
	Space = true,
	LeftShift = true,
	RightShift = true,
	Slash = true,
}

local SettingsService = {
	Name = "SettingsService",
	PlayerSettings = ServerComm:CreateProperty("PlayerSettings", {}),
	SettingsTemplate = {},
	Settings = {},
	SettingChanged = Signal.new() :: Signal.Signal<Player, string, Types.SettingValue>,
}

function SettingsService:OnInit()
	PlayerDataService.DocumentLoaded:Connect(function(Player: Player, Document)
		local Data = Document:read()
		self.PlayerSettings:SetFor(Player, Data.Settings)
	end)
	ChangeSetting:SetCallback(function(Player: Player, SettingName: string, Value: Types.SettingValue)
		return self:ChangeSettingNetworkRequest(Player, SettingName, Value)
	end)
end

function SettingsService:GetSettings(Player: Player): Types.PlayerDataSettings?
	local document = PlayerDataService:GetDocument(Player)
	if document then
		return document:read().Settings
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
		elseif Setting.Type == "Keybind" then
			for device, enum in pairs(Value) do
				if table.find(AllowedDevices, device) == nil then
					return false
				end
				if (enum ~= "None" :: any) and not EnumUtils.IsEnum(Enum.KeyCode, enum) then
					return false
				end
				if RestrictedKeybinds[enum] then
					return false
				end
			end
		end
		return true
	end
	return false
end

function SettingsService:ChangeSettingNetworkRequest(
	Player: Player,
	SettingName: string,
	Value: Types.SettingValue
): Types.NetworkResponse
	local Setting = Settings[SettingName]
	local document = PlayerDataService:GetDocument(Player)
	if Setting and document then
		if self:IsValidValue(Setting, Value) then
			local oldData = document:read()
			local newSettingInternal = {
				Value = Value,
			}

			local newData = Freeze.Dictionary.setIn(oldData, { "Settings", SettingName }, newSettingInternal)

			document:write(newData)

			SettingsService.SettingChanged:Fire(Player, SettingName, Value)
			return {
				Success = true,
				Message = "Setting changed successfully",
			}
		end
	end
	return {
		Success = false,
		Message = "Invalid setting or value",
	}
end
return SettingsService
