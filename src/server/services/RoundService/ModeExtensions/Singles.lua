-- Singles Extension
-- April 12th, 2024
-- Nick

-- // Variables \\

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Constants = ReplicatedStorage.constants
local Services = ServerScriptService.services

local Generic = require(script.Parent.Parent.Generic)
local RoundService = require(Services.RoundService)
local Types = require(Constants.Types)

local SinglesExtension = {
	Data = RoundService:GetRoundModeData("Singles"),
	StartMatch = Generic.StartMatch,
} :: Types.RoundModeExtension

return SinglesExtension