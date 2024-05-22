-- Nametag
-- April 1st, 2024
-- Nick

-- // Variables \\

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.packages
local Hooks = ReplicatedStorage.hooks
local Components = ReplicatedStorage.components
local Constants = ReplicatedStorage.constants
local IndicatorComponents = Components.indicators

local Healthbar = require(IndicatorComponents.Healthbar)
local React = require(Packages.React)
local ReactRoblox = require(Packages.ReactRoblox)
local Types = require(Constants.Types)
local useAttribute = require(Hooks.useAttribute)

local e = React.createElement

-- // Nametag \\

type NametagProps = {
	name: string,
	target: Instance?,
	entity: Types.Entity?,
	userId: number?,
}
local function Nametag(props: NametagProps)
	local level = useAttribute(props.userId and Players:GetPlayerByUserId(props.userId), "Level")

	return props.target ~= nil
		and ReactRoblox.createPortal(
			e("BillboardGui", {
				Active = true,
				Size = UDim2.fromScale(3.9, 1),
				StudsOffset = Vector3.new(0, 1.5, 0),
				ResetOnSpawn = false,
				ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
			}, {
				nametag = e("Frame", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Position = UDim2.fromScale(0.5, 0.5),
					Size = UDim2.fromScale(1, 0.93),
				}, {
					levelShape = e("ImageLabel", {
						Image = "rbxassetid://16896271836",
						ImageColor3 = Color3.fromRGB(35, 35, 35),
						ScaleType = Enum.ScaleType.Fit,
						AnchorPoint = Vector2.new(0, 0.5),
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
						Position = UDim2.fromScale(0, 0.5),
						Size = UDim2.fromScale(1, 1.1),
						SizeConstraint = Enum.SizeConstraint.RelativeYY,
						ZIndex = 2,
					}, {
						levelAmount = e("TextLabel", {
							FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json"),
							Text = string.format("%d", level or -1),
							TextColor3 = Color3.fromRGB(255, 255, 255),
							TextScaled = true,
							TextSize = 14,
							TextWrapped = true,
							AnchorPoint = Vector2.new(0.5, 0.5),
							BackgroundColor3 = Color3.fromRGB(255, 255, 255),
							BackgroundTransparency = 1,
							BorderSizePixel = 0,
							Position = UDim2.fromScale(0.5, 0.5),
							Size = UDim2.fromScale(0.6, 0.6),
						}, {
							uIStroke = e("UIStroke", {
								Thickness = 2.5,
								Transparency = 0.5,
							}),
						}),
					}),

					infoDisplay = e("Frame", {
						AnchorPoint = Vector2.new(0, 0.5),
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
						Position = UDim2.fromScale(0.18, 0.5),
						Size = UDim2.fromScale(0.9, 0.8),
					}, {
						playerNameBox = e("Frame", {
							BackgroundColor3 = Color3.fromRGB(50, 50, 50),
							BorderSizePixel = 0,
							Size = UDim2.fromScale(0.5, 0.6),
						}, {
							gradient = e("UIGradient", {
								Transparency = NumberSequence.new({
									NumberSequenceKeypoint.new(0, 0),
									NumberSequenceKeypoint.new(1, 1),
								}),
							}),
							playerName = e("TextLabel", {
								FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
								Text = props.name,
								TextColor3 = Color3.fromRGB(255, 255, 255),
								TextScaled = true,
								TextSize = 14,
								TextWrapped = true,
								TextXAlignment = Enum.TextXAlignment.Left,
								AnchorPoint = Vector2.new(0, 0.5),
								BackgroundColor3 = Color3.fromRGB(255, 255, 255),
								BackgroundTransparency = 1,
								BorderSizePixel = 0,
								Position = UDim2.fromScale(0.15, 0.5),
								Size = UDim2.fromScale(2.5, 0.75),
							}, {
								uIStroke1 = e("UIStroke", {
									Thickness = 2,
								}, {
									uIGradient1 = e("UIGradient", {
										Rotation = -90,
										Transparency = NumberSequence.new({
											NumberSequenceKeypoint.new(0, 0.65),
											NumberSequenceKeypoint.new(0.607, 1),
											NumberSequenceKeypoint.new(1, 1),
										}),
									}),
								}),
							}),
						}),

						healthBar = props.entity and e(Healthbar, {
							anchorPoint = Vector2.new(0, 1),
							backgroundColor = Color3.fromRGB(35, 35, 35),
							shouldFormat = true,
							position = UDim2.fromScale(0, 0.95),
							size = UDim2.fromScale(1, 0.3),
							humanoid = props.entity:FindFirstChildOfClass("Humanoid"),
							statisticIcon = nil,
							showPercentage = false,
							healthLines = 2,
							percentageTextAlignment = Enum.TextXAlignment.Center,
						}),
					}),
				}),
			}),
			props.target
		)
end

return Nametag
