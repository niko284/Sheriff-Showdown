local Generic = require("../Generic")
local RoundService = require("@services/RoundService")
local Types = require("@constants/Types")

local DuosExtension = {
	Data = RoundService:GetRoundModeData("Free For All"),
	StartMatch = Generic.StartMatch,
} :: Types.RoundModeExtension

return DuosExtension
