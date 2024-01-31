--!strict
-- Audio Service
-- February 28th, 2023
-- Nick

-- // Variables \\

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Constants = ReplicatedStorage.constants

local Audios = require(Constants.Audios)
local Types = require(Constants.Types)

-- // Service \\

local AudioService = {
	Name = "AudioService",
	SoundGroups = {} :: { [string]: SoundGroup },
}

-- // Functions \\

function AudioService:Init()
	for _AudioName, Audio in pairs(Audios) do
		if Audio.SoundGroupName and not AudioService.SoundGroups[Audio.SoundGroupName :: string] then
			local soundGroup = Instance.new("SoundGroup")
			AudioService.SoundGroups[Audio.SoundGroupName :: string] = soundGroup
			soundGroup.Name = Audio.SoundGroupName :: string
			soundGroup.Parent = SoundService
		end
	end
end

function AudioService:PlayPreset(presetName: string | Types.Audio, onPart: BasePart?): Sound?
	local presetAudio = (typeof(presetName) == "string" and Audios[presetName] or presetName) :: Types.Audio
	if not presetAudio then
		warn("%s is not a valid audio preset", presetName)
		return nil
	end
	local newSound = Instance.new("Sound")
	newSound.SoundId = presetAudio.AudioId
	if presetAudio.SoundGroupName then
		newSound.SoundGroup = AudioService.SoundGroups[presetAudio.SoundGroupName] -- If the audio has a sound group, set it
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

return AudioService
