--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local Controllers = LocalPlayer.PlayerScripts.controllers

local React = require(ReplicatedStorage.packages.React)
local RoundController = require(Controllers.RoundController)
local ReactSpring = require(ReplicatedStorage.packages.ReactSpring)

local useState = React.useState
local e = React.createElement
local useEffect = React.useEffect
local useRef = React.useRef

local TEXT_POSITION = UDim2.fromScale(0.5, 0.5)
local FADE_IN_POSITION = UDim2.fromScale(0.2, 0.5)
local FADE_OUT_POSITION = UDim2.fromScale(0.8, 0.5)

local function StatusText()
	local alternating = useRef(false)
	local oldStatusText = useRef("")

	local status, setStatus = useState({
		status = "",
		shouldAnimate = false,
	})

	-- if alternating is true, then the first text will fade out and the second text will fade in.
	local styles = ReactSpring.useSpring({
		from = {
			alternating1position = alternating.current and TEXT_POSITION or FADE_IN_POSITION,
			alternating2position = alternating.current and FADE_IN_POSITION or TEXT_POSITION,
			alternating1opacity = alternating.current and 0 or 1,
			alternating2opacity = alternating.current and 1 or 0,
		},
		to = {
			alternating1position = alternating.current and FADE_OUT_POSITION or TEXT_POSITION,
			alternating2position = alternating.current and TEXT_POSITION or FADE_OUT_POSITION,
			alternating1opacity = alternating.current and 1 or 0,
			alternating2opacity = alternating.current and 0 or 1,
		},
		reset = true,
	}, { status })

	useEffect(function()
		local updateStatusConnection = RoundController:ObserveStatusChanged(
			function(newStatus: string, shouldAnimate: boolean)
				alternating.current = not alternating.current
				setStatus(function(oldStatus)
					oldStatusText.current = oldStatus.status
					return {
						status = newStatus,
						shouldAnimate = shouldAnimate,
					}
				end)
			end
		)
		return function()
			updateStatusConnection:Disconnect()
		end
	end, {})

	return e("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0.347, 0.05),
		Size = UDim2.fromOffset(586, 135),
	}, {
		alternating1 = e("TextLabel", {
			FontFace = Font.new(
				"rbxasset://fonts/families/SourceSansPro.json",
				Enum.FontWeight.Bold,
				Enum.FontStyle.Normal
			),
			Text = alternating.current and oldStatusText.current or status.status,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 28,
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = styles.alternating1position,
			Size = UDim2.fromScale(1, 0.5),
			TextTransparency = styles.alternating1opacity,
		}, {
			stroke = e("UIStroke", {
				Transparency = styles.alternating1opacity,
			}),
		}),

		alternating2 = e("TextLabel", {
			FontFace = Font.new(
				"rbxasset://fonts/families/SourceSansPro.json",
				Enum.FontWeight.Bold,
				Enum.FontStyle.Normal
			),
			Text = alternating.current and status.status or oldStatusText.current,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 28,
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = styles.alternating2position,
			TextTransparency = styles.alternating2opacity,
			Size = UDim2.fromScale(1, 0.5),
		}, {
			stroke = e("UIStroke", {
				Transparency = styles.alternating2opacity,
			}),
		}),
	})
end

return StatusText
