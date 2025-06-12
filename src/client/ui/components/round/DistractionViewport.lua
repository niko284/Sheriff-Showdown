--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = ReplicatedStorage:FindFirstChild("assets") :: Folder

local React = require("@packages/React")
local RoundController = require("@controllers/RoundController")
local Types = require("@constants/Types")
local ViewportFrame = require("@ui/components/frames/ViewportFrame")

local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect

local DISTRACTION_SIGNS_FOLDER = Assets:FindFirstChild("distractions") :: Folder
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

	local distractionSign = currentDistraction and DISTRACTION_SIGNS_FOLDER:FindFirstChild(currentDistraction)

	return distractionSign
			and e(ViewportFrame, {
				size = UDim2.fromScale(1, 1),
				anchorPoint = Vector2.new(0.5, 0.5),
				position = UDim2.fromScale(0.5, 0.5),
				backgroundTransparency = 1,
				useDirectly = false,
				model = distractionSign :: Model,
				scrollToZoom = false,
				draggable = false,
				worldModel = true,
				onModelCreated = function(signModel: Model)
					local animationController = signModel:FindFirstChildOfClass("AnimationController") :: any
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
