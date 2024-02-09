-- Audio Controller
-- April 23rd, 2022
-- Nick

-- // Variables \\

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local LocalPlayer = Players.LocalPlayer
local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")
local Controllers = PlayerScripts.controllers
local Constants = ReplicatedStorage.constants

local Audios = require(Constants.Audios)
local Types = require(Constants.Types)

-- // Controller Variables \\

local AudioController = {
	Name = "AudioController",
	LoadedSongs = {},
}

-- // Functions \\

function AudioController:Init()
	AudioController.SettingsController = require(Controllers.SettingsController)
end

function AudioController:Start() end

function AudioController:LoadAudio(AudioId: string): Sound
	local Audio = Instance.new("Sound")
	Audio.SoundId = AudioId
	return Audio
end

function AudioController:PlayPreset(presetName: string | Types.Audio, onPart: BasePart?): Sound?
	local presetAudio = (typeof(presetName) == "string" and Audios[presetName] or presetName) :: Types.Audio
	if not presetAudio then
		warn("%s is not a valid audio preset", presetName)
		return nil
	end
	local newSound = Instance.new("Sound")
	newSound.SoundId = presetAudio.AudioId
	if presetAudio.SoundGroupName then
		newSound.SoundGroup = SoundService:WaitForChild(presetAudio.SoundGroupName)
	end
	if presetAudio.Volume then
		newSound.Volume = presetAudio.Volume
	end
	newSound.Looped = presetAudio.Looped or false
	if onPart then
		newSound.Parent = onPart
	else
		newSound.Parent = SoundService
	end
	newSound.Ended:Connect(function()
		newSound:Destroy()
	end)
	newSound:Play()
	return newSound
end

function AudioController:SetSoundGroupVolume(SoundGroupName: string, Volume: number)
	local soundGroup = SoundService:WaitForChild(SoundGroupName)
	soundGroup.Volume = Volume
end

return AudioController
