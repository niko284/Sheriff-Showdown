--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Components = ReplicatedStorage.react.components

local AutomaticScrollingFrame = require(Components.frames.AutomaticScrollingFrame)
local CrateTemplate = require(Components.shop.crates.CrateTemplate)
local Crates = require(ReplicatedStorage.constants.Crates)
local React = require(ReplicatedStorage.packages.React)
local Types = require(ReplicatedStorage.constants.Types)

local e = React.createElement

type CratePageProps = Types.FrameProps & {
	pageRef: (ref: Frame) -> (),
}

local function CratePage(props: CratePageProps)
	local crateElements = {}
	for crateName, crateInfo in Crates do
		crateElements[crateName] = e(CrateTemplate, {
			crateImage = string.format("rbxassetid://%d", crateInfo.ShopImage),
			crateName = crateName,
			crateDescription = string.format("Contains %d items", #crateInfo.ItemContents),
			rotationTime = 1,
			amountOfPreviewItems = 4,
			size = UDim2.fromOffset(254, 339),
		})
	end

	return e("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		LayoutOrder = props.layoutOrder,
		Size = UDim2.fromScale(1, 1.03),
		ref = function(rbx: Frame)
			props.pageRef(rbx)
		end,
	}, {
		crates = e("TextLabel", {
			FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Bold,
				Enum.FontStyle.Normal
			),
			Text = "Crates",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 16,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(18, 19),
			Size = UDim2.fromOffset(54, 13),
		}),

		cratesList = e(AutomaticScrollingFrame, {
			scrollBarThickness = 5,
			scrollingDirection = Enum.ScrollingDirection.X,
			active = true,
			backgroundTransparency = 1,
			anchorPoint = Vector2.new(0, 0),
			borderSizePixel = 0,
			position = UDim2.fromScale(0.00723, 0.104),
			size = UDim2.fromOffset(806, 356),
		}, {
			listLayout = e("UIListLayout", {
				Padding = UDim.new(0, 16),
				FillDirection = Enum.FillDirection.Horizontal,
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Center,
			}),

			padding = e("UIPadding", {
				PaddingBottom = UDim.new(0, 10),
				PaddingLeft = UDim.new(0, 7),
			}),

			crates = e(React.Fragment, nil, crateElements :: any),
		}),
	})
end

return React.memo(CratePage)
