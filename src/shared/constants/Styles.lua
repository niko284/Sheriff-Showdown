--!strict
-- Styles
-- Nick
-- June 8th, 2023

-- // Variables \\

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = ReplicatedStorage.constants

local Types = require(Constants.Types)

local function toAsset(id: number): string
	return string.format("rbxassetid://%d", id)
end

local function CreateAnimation(id: number): Animation
	local animation = Instance.new("Animation")
	animation.AnimationId = toAsset(id)
	return animation
end

local Styles: Types.StylesTable = {
	Default = {
		PassiveAnimations = {
			walk = CreateAnimation(15097762078),
			run = CreateAnimation(10347663478),
			idle = CreateAnimation(10347661130),
			fall = CreateAnimation(9933573732),
			jump = CreateAnimation(9933575836),
			climb = nil,
			sprint = CreateAnimation(10606641167),
		},
		Shoot = CreateAnimation(16206869874),
	},
	OneHandedDefault = {
		PassiveAnimations = {
			idle = CreateAnimation(17048490453),
		},
	},
}

return Styles
