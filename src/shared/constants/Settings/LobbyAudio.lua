local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AudioUtils = require(ReplicatedStorage.utils.AudioUtils)

return {
	Name = "Lobby Audio",
	Description = "Input an audio ID for your own lobby music.",
	Type = "Input",
	Category = "Audio",
	Icon = "rbxassetid://8852793083",
	Default = "",
	InputVerifiers = {
		AudioUtils.IsValidSoundId,
	},
}
