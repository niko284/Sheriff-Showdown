local AudioUtils = require("@utilities/AudioUtils")

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
