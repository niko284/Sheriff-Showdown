-- Distraction Viewport
-- April 20th, 2024
-- Nick

-- // Variables \\

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerScripts = LocalPlayer.PlayerScripts

local Packages = ReplicatedStorage.packages
local Components = ReplicatedStorage.components
local FrameComponents = Components.frames
local Controllers = PlayerScripts.controllers
local Constants = ReplicatedStorage.constants
local Assets = ReplicatedStorage:FindFirstChild("assets")

local RoundController = require(Controllers.RoundController)
local Types = require(Constants.Types)
local ViewportFrame = require(FrameComponents.ViewportFrame)

local React = require(Packages.React)

local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect

local DISTRACTION_SIGNS_FOLDER = Assets:FindFirstChild("distractions")
local SIGN_ANIMATION_ID = 16815368354

-- // Distraction Viewport \\

local function DistractionViewport()
	local currentDistraction, setCurrentDistraction = useState(nil :: Types.Distraction?)

	useEffect(function()
		local distractionSignal = RoundController.DistractionReceived:Connect(function(distraction)
			setCurrentDistraction(distraction)
		end)

		return function()
			distractionSignal:Disconnect()
		end
	end, {})

	local distractionSign = currentDistraction and DISTRACTION_SIGNS_FOLDER:FindFirstChild(currentDistraction) or nil

	return distractionSign
			and e(ViewportFrame, {
				size = UDim2.fromScale(1, 1),
				anchorPoint = Vector2.new(0.5, 0.5),
				position = UDim2.fromScale(0.5, 0.5),
				backgroundTransparency = 1,
				useDirectly = false,
				model = distractionSign,
				scrollToZoom = false,
				draggable = false,
				worldModel = true,
				onModelCreated = function(signModel: Model)
					local animationController = signModel:FindFirstChildOfClass("AnimationController")
					if animationController then
						local signAnimationId = string.format("rbxassetid://%d", SIGN_ANIMATION_ID)
						local signAnimation = Instance.new("Animation")
						signAnimation.AnimationId = signAnimationId

						local signAnimationTrack = animationController:LoadAnimation(signAnimation) :: AnimationTrack
						signAnimationTrack.Looped = false
						signAnimationTrack:Play()
					end
				end,
			})
		or nil
end

return DistractionViewport
