-- Round Utils
-- April 13th, 2024
-- Nick

-- // Variables \\

local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local IS_SERVER = RunService:IsServer()

-- // Util Variables \\

local RoundUtils = {}

-- // Functions \\

function RoundUtils.GetCurrentRound()
	if IS_SERVER then
		local roundService = require(ServerScriptService.services.RoundService)
		return roundService:GetRound()
	end
end

function RoundUtils.GetRoundModeExtension(RoundMode)
	if IS_SERVER then
		local roundService = require(ServerScriptService.services.RoundService)
		return roundService:GetRoundModeExtension(RoundMode)
	end
end

return RoundUtils
