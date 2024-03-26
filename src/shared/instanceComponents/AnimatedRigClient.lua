-- Animated Rig
-- February 19th, 2024
-- Nick

-- // Variables \\

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Packages = ReplicatedStorage.packages
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Component = require(Packages.Component)

-- // Entity \\

local AnimatedRig = Component.new({
	Tag = "AnimatedRig",
	Ancestors = { workspace, PlayerGui },
	Extensions = {},
})

-- // Functions \\

function AnimatedRig:Construct()
	self._controller = self.Instance:FindFirstChildOfClass("AnimationController")
	self:StartAnimations()
end

function AnimatedRig:StartAnimations()
	local animController = self._controller :: AnimationController?
	if not animController then
		warn("No AnimationController found in: ", self.Instance:GetFullName())
		return
	end

	local idleAnimation = self.Instance:GetAttribute("IdleAnimation")
	if idleAnimation then
		local animation = Instance.new("Animation")
		animation.AnimationId = string.format("rbxassetid://%d", idleAnimation)
		local idleTrack = animController:LoadAnimation(animation) :: AnimationTrack
		idleTrack.Looped = true
		idleTrack:Play()
	end
end

function AnimatedRig:Stop() end

return AnimatedRig
