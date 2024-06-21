--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Components = ReplicatedStorage.react.components

local Button = require(Components.buttons.Button)
local Crates = require(ReplicatedStorage.constants.Crates)
local ItemUtils = require(ReplicatedStorage.utils.ItemUtils)
local OptionButton = require(Components.buttons.OptionButton)
local React = require(ReplicatedStorage.packages.React)
local Timer = require(ReplicatedStorage.packages.Timer)
local Types = require(ReplicatedStorage.constants.Types)

local e = React.createElement
local useEffect = React.useEffect

type CrateTemplateProps = Types.FrameProps & {
	crateImage: string,
	crateName: Types.Crate,
	crateDescription: string,
	rotationTime: number,
	amountOfPreviewItems: number,
}

local function CrateTemplate(props: CrateTemplateProps)
	local crateInfo = Crates[props.crateName]

	local previewContents, setPreviewContents = React.useState({} :: { number }) -- Item Ids

	useEffect(function()
		local rotationTimer = Timer.new(props.rotationTime)
		rotationTimer.Tick:Connect(function()
			-- Pick new contents to show at random

			local newContents = {}
			local itemNames = table.clone(crateInfo.ItemContents)

			for _ = 1, props.amountOfPreviewItems do
				if #itemNames == 0 then
					break
				end
				local randomItemName = table.remove(itemNames, math.random(1, #itemNames)) :: string

				local itemFromName = ItemUtils.GetItemInfoFromName(randomItemName)
				if itemFromName then
					table.insert(newContents, itemFromName.Id)
				end
			end

			setPreviewContents(newContents)
		end)

		rotationTimer:StartNow()

		return function()
			rotationTimer:Destroy()
		end
	end, { props.rotationTime, props.amountOfPreviewItems })

	local previewElements = {}
	for _, itemId in previewContents do
		local itemInfo = ItemUtils.GetItemInfoFromId(itemId)
		previewElements[itemId] = e("Frame", {
			BackgroundColor3 = Color3.fromRGB(133, 133, 133),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(14, 14),
			Size = UDim2.fromOffset(53, 53),
		}, {
			contentImage = e("ImageLabel", {
				Image = string.format("rbxassetid://%d", itemInfo.Image),
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(6, 6),
				Size = UDim2.fromOffset(42, 43),
			}),

			corner = e("UICorner", {
				CornerRadius = UDim.new(0, 3),
			}),

			stroke = e("UIStroke", {
				Color = Color3.fromRGB(158, 158, 158),
			}),
		})
	end

	return e("Frame", {
		BackgroundColor3 = Color3.fromRGB(72, 72, 72),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Size = props.size,
	}, {
		corner = e("UICorner", {
			CornerRadius = UDim.new(0, 5),
		}),

		stroke = e("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = Color3.fromRGB(255, 255, 255),
		}),

		crateImage = e("ImageLabel", {
			Image = props.crateImage,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(45, 74),
			Size = UDim2.fromOffset(166, 166),
			ZIndex = 0,
		}),

		purchaseButton = e(Button, {
			text = "Purchase",
			textColor3 = Color3.fromRGB(0, 53, 25),
			gradient = ColorSequence.new(Color3.fromRGB(68, 252, 153), Color3.fromRGB(35, 203, 112)),
			cornerRadius = UDim.new(0, 5),
			textSize = 16,
			anchorPoint = Vector2.new(0.5, 0.5),
			position = UDim2.fromScale(0.388, 0.901),
			size = UDim2.fromOffset(181, 45),
			fontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Bold,
				Enum.FontStyle.Normal
			),
			applyStrokeMode = Enum.ApplyStrokeMode.Border,
			strokeColor = Color3.fromRGB(255, 255, 255),
			strokeThickness = 1.5,
			gradientRotation = -90,
		}),

		viewContents = e(OptionButton, {
			anchorPoint = Vector2.new(0.5, 0.5),
			size = UDim2.fromOffset(45, 45),
			position = UDim2.fromScale(0.852, 0.901),
			image = "rbxassetid://18141436407",
			gradient = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 255, 255)),
			backgroundColor3 = Color3.fromRGB(255, 255, 255),
		}),

		crateName = e("TextLabel", {
			FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Bold,
				Enum.FontStyle.Normal
			),
			Text = props.crateName,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 16,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(22, 35),
			Size = UDim2.fromOffset(99, 13),
		}),

		description = e("TextLabel", {
			FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Medium,
				Enum.FontStyle.Normal
			),
			Text = props.crateDescription,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 14,
			TextTransparency = 0.369,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(22, 53),
			Size = UDim2.fromOffset(81, 14),
		}),

		contentDisplay = e("Frame", {
			BackgroundColor3 = Color3.fromRGB(103, 103, 103),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(0, 183),
			Size = UDim2.fromOffset(253, 81),
		}, {
			contentList = e("Frame", {
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0.0435, 0.111),
				Size = UDim2.fromOffset(231, 62),
			}, {
				listLayout = e("UIListLayout", {
					Padding = UDim.new(0, 6),
					FillDirection = Enum.FillDirection.Horizontal,
					SortOrder = Enum.SortOrder.LayoutOrder,
					VerticalAlignment = Enum.VerticalAlignment.Center,
				}),
				previews = e(React.Fragment, nil, previewElements),
			}),
		}),
	})
end

return React.memo(CrateTemplate)
