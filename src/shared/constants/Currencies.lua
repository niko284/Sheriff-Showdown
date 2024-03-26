-- Currencies
-- February 24th, 2024
-- Nick

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = ReplicatedStorage.constants

local Types = require(Constants.Types)

return {
	Coins = {
		Image = 16419213714,
		GradientColor = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(0.121, Color3.fromRGB(255, 234, 0)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 151, 2)),
		}),
	},
	Gems = {
		Image = 16418819111,
		GradientColor = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(0.0657, Color3.fromRGB(229, 255, 255)),
			ColorSequenceKeypoint.new(0.419, Color3.fromRGB(7, 255, 255)),
			ColorSequenceKeypoint.new(0.796, Color3.fromRGB(73, 231, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(88, 106, 120)),
		}),
	},
} :: { [Types.Currency]: Types.CurrencyInfo }
