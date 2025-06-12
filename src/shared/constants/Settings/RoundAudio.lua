local AudioUtils = require("@utilities/AudioUtils")

return {
	Name = "Round Audio",
	Description = "Input an audio ID for your round music.",
	Type = "Input",
	Category = "Audio",
	Icon = "rbxassetid://8852793083",
	Default = "",
	InputVerifiers = {
		AudioUtils.IsValidSoundId,
	},
}
