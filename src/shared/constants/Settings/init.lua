--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.constants.Types)

local settings = {}

for _, settingModule in script:GetChildren() do
	local setting = require(settingModule) :: Types.Setting
	settings[setting.Name] = setting
end

return settings :: { [string]: Types.Setting }
