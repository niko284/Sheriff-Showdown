local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Constants = ReplicatedStorage.constants
local Services = ServerScriptService.services

local Generic = require(script.Parent.Parent.Generic)
local RoundService = require(Services.RoundService)
local Types = require(Constants.Types)

local DuosExtension = {
	Data = RoundService:GetRoundModeData("Free For All"),
	StartMatch = Generic.StartMatch,
} :: Types.RoundModeExtension

return DuosExtension