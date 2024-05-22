--!strict
-- Audio Utils
-- July 28th, 2023
-- Nick

-- // Variables \\

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local Constants = ReplicatedStorage.constants

local Audios = require(Constants.Audios)
local Types = require(Constants.Types)

local IS_SERVER = RunService:IsServer()
local IS_CLIENT = RunService:IsClient()

-- // Audio Utils \\

local AudioUtils = {}

function AudioUtils.PlayPreset(SoundType: string | Types.Audio, Part: BasePart?)
	if IS_SERVER then
		local AudioService = require(ServerScriptService.services.AudioService)
		AudioService:PlayPreset(SoundType, Part)
	elseif IS_CLIENT then
		local LocalPlayer = Players.LocalPlayer
		local controllers = LocalPlayer.PlayerScripts.controllers
		local AudioController = require(controllers.AudioController)
		AudioController:PlayPreset(SoundType, Part)
	end
end

function AudioUtils.BuildAbilitySounds(AbilityName: string, TargetEntity: Types.Entity, Track: AnimationTrack?): ()
	local audioInfo = Audios[AbilityName]

	if not audioInfo.AudioId then
		for markerName, soundInfo in pairs(audioInfo) do
			if markerName == "Start" then -- play it once the ability starts.
				AudioUtils.PlayPreset(soundInfo.SoundId, TargetEntity.PrimaryPart)
			elseif Track then
				Track:GetMarkerReachedSignal(markerName):Connect(function()
					AudioUtils.PlayPreset((audioInfo :: any)[markerName], TargetEntity.PrimaryPart)
				end)
			end
		end
	else
		AudioUtils.PlayPreset(AbilityName, TargetEntity.PrimaryPart)
	end
end

return AudioUtils
