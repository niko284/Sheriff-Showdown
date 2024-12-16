--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Components = ReplicatedStorage.react.components

local AutomaticScrollingFrame = require(Components.frames.AutomaticScrollingFrame)
local GamepassTemplate = require(Components.shop.gamepasses.GamepassTemplate)
local Gamepasses = require(ReplicatedStorage.constants.Gamepasses)
local React = require(ReplicatedStorage.packages.React)

local e = React.createElement

type GamepassPageProps = {
	pageRef: (ref: Frame) -> (),
}

local function GamepassPage(props: GamepassPageProps)
	local gamepassElements = {}
	for _, gamepass in Gamepasses do
		gamepassElements[gamepass.GamepassId] = e(GamepassTemplate, {
			gamepassId = gamepass.GamepassId,
		})
	end

	return e("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1.03),
		ref = function(rbx: Frame)
			props.pageRef(rbx)
		end,
	}, {
		gamepass = e("TextLabel", {
			FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Bold,
				Enum.FontStyle.Normal
			),
			Text = "Gamepasses",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 20,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(13, 18),
			Size = UDim2.fromOffset(87, 15),
		}),

		gamepassList = e(AutomaticScrollingFrame, {
			anchorPoint = Vector2.new(0, 0),
			scrollBarThickness = 9,
			active = true,
			backgroundTransparency = 1,
			borderSizePixel = 0,
			position = UDim2.fromScale(0.0133, 0.117),
			size = UDim2.fromOffset(801, 332),
		}, {
			padding = e("UIPadding", {
				PaddingLeft = UDim.new(0, 5),
				PaddingTop = UDim.new(0, 5),
			}),
			gridLayout = e("UIGridLayout", {
				CellPadding = UDim2.fromOffset(15, 15),
				CellSize = UDim2.fromOffset(245, 166),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			passes = e(React.Fragment, nil, gamepassElements),
		}),
	})
end

return React.memo(GamepassPage)
