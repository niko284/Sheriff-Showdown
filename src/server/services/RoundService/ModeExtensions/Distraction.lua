--!strict

local jecs = require("@packages/jecs")

local Actions = require("@ecs/actions")
local BlinkServer = require("@server/modules/BlinkServer")
local Components = require("@ecs/components")
local Distractions = require("@constants/Distractions")
local Generic = require("../Generic")
local Promise = require("@packages/Promise")
local RoundService = require("@services/RoundService")
local Sift = require("@packages/Sift")
local Types = require("@constants/Types")

local DISTRACTION_KEYS = Sift.Dictionary.keys(Distractions)
local DISTRACTION_STOP_FLAG = "ImmediateStop"

local DISALLOWED_ACTIONS_DURING_DISTRACTION = {
	"Shoot",
}

local DistractionExtension = {
	Data = RoundService:GetRoundModeData("Distraction"),
	ExtraMatchProperties = {
		DistractionsFinished = false,
	},
} :: Types.RoundModeExtension & {
	GetDistractions: () -> { Types.Distraction },
}

function DistractionExtension.StartMatch(Match: Types.Match, RoundInstance: Types.Round, World: jecs.World)
	Generic.StartMatch(Match, RoundInstance, World)

	local matchDistractions = DistractionExtension.GetDistractions()
	local distractionsActive = true
	local playersInMatch = RoundService:GetAllPlayersInMatch(Match)

	local distractionMiddleware = function(_world, player: Player, _actionPayload: any)
		if distractionsActive and table.find(playersInMatch, player) then
			local playerEntityId = RoundService:GetEntityIdFromPlayer(player)
			if not World:get(playerEntityId, Components.Killed) then
				World:set(playerEntityId, Components.Killed, {
					killerEntityId = playerEntityId,
					expiry = os.time() + 6,
					processRemoval = false,
				})
			end
			return false
		end
		return true
	end

	for _, action in DISALLOWED_ACTIONS_DURING_DISTRACTION do
		local actionType = Actions[action]
		local actionMiddlewares = actionType.middleware or {}
		table.insert(actionMiddlewares, distractionMiddleware)
	end

	Promise.any({
		Generic.MatchFinishedPromise(Match):andThen(function()
			BlinkServer.RoundSendDistraction.FireList(playersInMatch, DISTRACTION_STOP_FLAG)
			distractionsActive = false
			return DISTRACTION_STOP_FLAG
		end),
		Promise.new(function(resolve, _reject, onCancel)
			local distractionsSent = 0
			local distractionsToSend = #matchDistractions

			onCancel(function()
				distractionsSent = distractionsToSend
			end)

			while distractionsSent < distractionsToSend do
				local distraction = matchDistractions[distractionsSent + 1]
				BlinkServer.RoundSendDistraction.FireList(playersInMatch, distraction)
				distractionsSent += 1
				if distractionsSent < distractionsToSend then
					task.wait(3)
				end
			end

			resolve("Success")
		end),
	}):finally(function(result: "Success" | "ImmediateStop")
		distractionsActive = false
		task.spawn(function()
			task.wait(1)
			BlinkServer.RoundSendDistraction.FireList(playersInMatch, nil)
		end)

		for _, action in DISALLOWED_ACTIONS_DURING_DISTRACTION do
			local actionType = Actions[action]
			local actionMiddlewares = actionType.middleware or {}
			local index = table.find(actionMiddlewares, distractionMiddleware)
			if index then
				table.remove(actionMiddlewares, index)
			end
		end

		if result == DISTRACTION_STOP_FLAG then
			return
		end
	end)
end

function DistractionExtension.GetDistractions(): { Types.Distraction }
	local distractions: { Types.Distraction } = {}
	local distractionsBeforeDraw = math.random(0, 6)

	for _i = 1, distractionsBeforeDraw do
		local distractionName = nil
		repeat
			distractionName = DISTRACTION_KEYS[math.random(1, #DISTRACTION_KEYS)]
		until distractionName ~= "Draw" and distractions[#distractions] ~= distractionName
		table.insert(distractions, distractionName)
	end

	table.insert(distractions, "Draw")

	return distractions
end

return DistractionExtension
