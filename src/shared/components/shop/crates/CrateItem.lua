-- Crate Item
-- February 24th, 2024
-- Nick

-- // Variables \\

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Packages = ReplicatedStorage.packages
local Constants = ReplicatedStorage.constants
local Utils = ReplicatedStorage.utils
local PlayerScripts = LocalPlayer.PlayerScripts
local Controllers = PlayerScripts.controllers

local ItemController = require(Controllers.ItemController)
local React = require(Packages.React)
local Types = require(Constants.Types)

local useRef = React.useRef
local e = React.createElement

-- // Crate Item \\

type CrateItemProps = Types.FrameProps & {
	itemInfo: Types.ItemInfo,
}

local function CrateItem(props: CrateItemProps)
	local rarityProbabilities = ItemController:GetRarityProbabilities()
	local rarityProbability = rarityProbabilities[props.itemInfo.Rarity]

	return e("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Size = props.size,
		LayoutOrder = props.layoutOrder,
	}, {
		image = e("ImageButton", {
			Image = string.format("rbxassetid://%d", props.itemInfo.Image),
			ScaleType = Enum.ScaleType.Fit,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.0418, 0.0435),
			Size = UDim2.fromOffset(71, 71),
		}),

		uIGradient = e("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
				ColorSequenceKeypoint.new(0.439, Color3.fromRGB(255, 255, 255)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
			}),
			Rotation = -90,
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.814),
				NumberSequenceKeypoint.new(0.702, 1),
				NumberSequenceKeypoint.new(1, 1),
			}),
		}),

		uIStroke = e("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = Color3.fromRGB(255, 255, 255),
			Thickness = 2,
			Transparency = 0.7,
		}, {
			uIGradient1 = e("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
					ColorSequenceKeypoint.new(0.465, Color3.fromRGB(255, 255, 255)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
				}),
				Rotation = -90,
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0),
					NumberSequenceKeypoint.new(0.498, 1),
					NumberSequenceKeypoint.new(1, 1),
				}),
			}),
		}),

		name = e("TextLabel", {
			FontFace = Font.new(
				"rbxasset://fonts/families/SourceSansPro.json",
				Enum.FontWeight.Bold,
				Enum.FontStyle.Normal
			),
			Text = props.itemInfo.Name,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextScaled = true,
			TextSize = 14,
			TextWrapped = true,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0, 0.809),
			Size = UDim2.fromOffset(75, 20),
		}),

		uICorner = e("UICorner"),

		percentage = e("TextLabel", {
			FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Bold,
				Enum.FontStyle.Normal
			),
			Text = string.format("%d%%", rarityProbability * 100),
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextScaled = true,
			TextSize = 14,
			TextWrapped = true,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.598, 0.0751),
			Size = UDim2.fromOffset(30, 21),
		}, {
			uIStroke1 = e("UIStroke", {
				Thickness = 2,
			}),
		}),
	})
end

return React.memo(CrateItem)
