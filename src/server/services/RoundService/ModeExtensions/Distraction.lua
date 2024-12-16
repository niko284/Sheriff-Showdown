-- Distraction Extension
-- April 12th, 2024
-- Nick

-- // Variables \\

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Packages = ReplicatedStorage.packages
local Constants = ReplicatedStorage.constants
local Serde = ReplicatedStorage.serde
local Services = ServerScriptService.services

local ActionService = require(Services.ActionService)
local AudioService = require(Services.AudioService)
local Distractions = require(Constants.Distractions)
local Generic = require(script.Parent.Parent.Generic)
local HitFXSerde = require(Serde.HitFXSerde)
local Promise = require(Packages.Promise)
local Remotes = require(ReplicatedStorage.network.Remotes)
local RoundService = require(Services.RoundService)
local Sift = require(Packages.Sift)
local Types = require(Constants.Types)

local EntityNamespace = Remotes.Server:GetNamespace("Entity")
local RoundNamespace = Remotes.Server:GetNamespace("Round")
local SendDistraction = RoundNamespace:Get("SendDistraction")
local ProcessFX = EntityNamespace:Get("ProcessFX")

local DISTRACTION_KEYS = Sift.Dictionary.keys(Distractions)
local DISTRACTION_STOP_FLAG = "ImmediateStop"

local DistractionExtension = {
	Data = RoundService:GetRoundModeData("Distraction"),
	ExtraMatchProperties = {
		-- we can add extra properties here for newly created rounds if we need to.
		DistractionsFinished = false,
	},
} :: Types.RoundModeExtension

function DistractionExtension.StartMatch(Match: Types.Match, _RoundInstance: Types.Round)
	Generic.StartMatch(Match)

	local matchDistractions = DistractionExtension.GetDistractions()

	-- loop through the distractions and send them to the clients to display every 2 seconds.
	local playersInMatch = RoundService:GetAllPlayersInMatch(Match)

	-- if our match finishes early, we want to stop the distractions from being sent to the clients.
	Promise.any({
		Generic.MatchFinishedPromise(Match):andThen(function()
			-- notify the client to stop the distractions if the match finishes early.
			SendDistraction:SendToPlayers(playersInMatch, DISTRACTION_STOP_FLAG)
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
		task.spawn(function()
			task.wait(1)
			SendDistraction:SendToPlayers(playersInMatch, nil) -- clear the draw distraction after 1 second.
		end)

		-- if the match finishes early, there's nothing left to do.
		if result == DISTRACTION_STOP_FLAG then
			return
		end
		-- since the draw distraction is the last one, we can now disable the distraction flag.

		Match.DistractionsFinished = true
	end)
end

function DistractionExtension.VerifyActionRequest(ActionPlayer: Player, StateInfo: Types.ActionStateInfo): boolean
	if not ActionPlayer.Character then
		return false
	end

	local humanoid = ActionPlayer.Character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return false
	end

	if StateInfo.ActionHandlerName == "Shoot" then
		local actionPlayerMatch = Generic.GetCurrentMatchForPlayer(ActionPlayer)
		if actionPlayerMatch and actionPlayerMatch.DistractionsFinished == false then
			-- here, we need to instantly kill the player if they shoot during the distraction phase.
			ActionService:DamageEntity(ActionPlayer.Character :: Types.Entity, humanoid.Health)

			local vfxArgs: Types.VFXArguments = {
				TargetEntity = ActionPlayer.Character,
			}

			ProcessFX:SendToAllPlayers(
				StateInfo.ActionHandlerName,
				"ExplosionDistraction",
				HitFXSerde.Serialize(vfxArgs)
			)
			AudioService:PlayPreset("DistractionExplosion", ActionPlayer.Character.PrimaryPart)

			return false
		end
	end

	return true
end

function DistractionExtension.GetDistractions(): { Types.Distraction }
	-- put a random amount of distractions in a list
	local distractions = {}
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
