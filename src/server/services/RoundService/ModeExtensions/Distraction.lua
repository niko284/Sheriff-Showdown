--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Packages = ReplicatedStorage.packages
local Constants = ReplicatedStorage.constants
local Services = ServerScriptService.services

local Actions = require(ReplicatedStorage.ecs.actions)
local Components = require(ReplicatedStorage.ecs.components)
local Distractions = require(Constants.Distractions)
local Generic = require(script.Parent.Parent.Generic)
local Matter = require(Packages.Matter)
local Net = require(Packages.Net)
local Promise = require(Packages.Promise)
local Remotes = require(ReplicatedStorage.network.Remotes)
local RoundService = require(Services.RoundService)
local Sift = require(Packages.Sift)
local Types = require(Constants.Types)

local RoundNamespace = Remotes.Server:GetNamespace("Round")
local SendDistraction = RoundNamespace:Get("SendDistraction") :: Net.ServerSenderEvent

local DISTRACTION_KEYS = Sift.Dictionary.keys(Distractions)
local DISTRACTION_STOP_FLAG = "ImmediateStop"

local DISALLOWED_ACTIONS_DURING_DISTRACTION = {
	"Shoot",
}

local DistractionExtension = {
	Data = RoundService:GetRoundModeData("Distraction"),
	ExtraMatchProperties = {
		-- we can add extra properties here for newly created rounds if we need to.
		DistractionsFinished = false,
	},
} :: Types.RoundModeExtension & {
	GetDistractions: () -> { Types.Distraction },
}

function DistractionExtension.StartMatch(Match: Types.Match, RoundInstance: Types.Round, World: Matter.World)
	Generic.StartMatch(Match, RoundInstance, World)

	local matchDistractions = DistractionExtension.GetDistractions()

	local distractionsActive = true

	-- loop through the distractions and send them to the clients to display every 2 seconds.
	local playersInMatch = RoundService:GetAllPlayersInMatch(Match)

	-- we need a stable reference to the function so we can remove it from the middleware table after the distractions end.
	local distractionMiddleware = function(_world, player: Player, _actionPayload: any)
		if distractionsActive and table.find(playersInMatch, player) then
			local playerEntityId = RoundService:GetEntityIdFromPlayer(player)
			local playerKilled = World:get(playerEntityId, Components.Killed)

			if playerKilled == nil then
				World:insert(
					playerEntityId,
					Components.Killed({
						killerEntityId = playerEntityId,
						expiry = os.time() + 6, -- 6 seconds duration
						processRemoval = false,
					})
				)
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

	-- if our match finishes early, we want to stop the distractions from being sent to the clients.
	Promise.any({
		Generic.MatchFinishedPromise(Match):andThen(function()
			-- notify the client to stop the distractions if the match finishes early.
			SendDistraction:SendToPlayers(playersInMatch, DISTRACTION_STOP_FLAG)
			distractionsActive = false
			return DISTRACTION_STOP_FLAG
		end),
		Promise.new(function(resolve, _reject, onCancel)
			local distractionsSent = 0
			local distractionsToSend = #matchDistractions
			local distractions = matchDistractions

			onCancel(function()
				distractionsSent = distractionsToSend -- stop the loop
			end)

			while distractionsSent < distractionsToSend do
				local distraction = distractions[distractionsSent + 1]
				SendDistraction:SendToPlayers(playersInMatch, distraction)
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
			SendDistraction:SendToPlayers(playersInMatch, nil) -- clear the draw distraction after 1 second.
		end)

		for _, action in DISALLOWED_ACTIONS_DURING_DISTRACTION do
			local actionType = Actions[action]
			local actionMiddlewares = actionType.middleware or {}
			local index = table.find(actionMiddlewares, distractionMiddleware)
			if index then
				table.remove(actionMiddlewares, index)
			end
		end

		-- if the match finishes early, there's nothing left to do.
		if result == DISTRACTION_STOP_FLAG then
			return
		end
		-- since the draw distraction is the last one, we can now disable the distraction flag.
	end)
end

function DistractionExtension.GetDistractions(): { Types.Distraction }
	-- put a random amount of distractions in a list
	local distractions: { Types.Distraction } = {}
	local distractionsBeforeDraw = math.random(0, 6)

	for _i = 1, distractionsBeforeDraw do
		local distractionName = nil
		repeat
			distractionName = DISTRACTION_KEYS[math.random(1, #DISTRACTION_KEYS)]
		until distractionName ~= "Draw" and distractions[#distractions] ~= distractionName
		table.insert(distractions, distractionName)
	end

	-- put the draw in the list last
	table.insert(distractions, "Draw")

	return distractions
end

return DistractionExtension
