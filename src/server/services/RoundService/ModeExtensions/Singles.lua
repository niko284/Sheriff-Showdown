local Generic = require(script.Parent.Parent.Generic)
local RoundService = require("@services/RoundService")
local Types = require("@constants/Types")

local SinglesExtension = {
	Data = RoundService:GetRoundModeData("Singles"),
	StartMatch = Generic.StartMatch,
} :: Types.RoundModeExtension

return SinglesExtension
