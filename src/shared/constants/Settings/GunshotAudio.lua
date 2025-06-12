local AudioUtils = require("@utilities/AudioUtils")

return {
	Name = "Gun Shot Audio",
	Description = "Input an audio ID for your gun shot sound.",
	Type = "Input",
	Category = "Audio",
	Icon = "rbxassetid://8852793083",
	Default = "",
	InputVerifiers = {
		AudioUtils.IsValidSoundId,
	},
}
