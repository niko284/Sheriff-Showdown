--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Components = ReplicatedStorage.react.components
local Controllers = LocalPlayer.PlayerScripts.controllers

local ShopController = require(Controllers.ShopController)
local Button = require(Components.buttons.Button)
local React = require(ReplicatedStorage.packages.React)
local ItemUtils = require(ReplicatedStorage.utils.ItemUtils)
local ReactSpring = require(ReplicatedStorage.packages.ReactSpring)
local Rarities = require(ReplicatedStorage.constants.Rarities)
local Types = require(ReplicatedStorage.constants.Types)

local CurrentCamera = workspace.CurrentCamera
local e = React.createElement
local useEffect = React.useEffect
local useRef = React.useRef
local useState = React.useState

local function CrateClaim()
	local crateItemId, setCrateItemId = useState(nil :: number?)
	local currentCleaner = useRef(nil :: (() -> ())?)

	local styles = ReactSpring.useSpring({
		position = crateItemId and UDim2.fromScale(0.5, 0.8) or UDim2.fromScale(0.314, 2),
		config = { duration = 0.3 },
		reset = crateItemId,
	}, { crateItemId })

	useEffect(function()
		local crateOpenedConn = ShopController.CrateOpened:Connect(function(_crate, gunId: any, cleaner)
			setCrateItemId(gunId)
			currentCleaner.current = cleaner
		end)
		return function()
			crateOpenedConn:Disconnect()
		end
	end, {})

	local crateItem = nil
	if crateItemId ~= nil then
		crateItem = ItemUtils.GetItemInfoFromId(crateItemId :: any)
	end

	return e("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = styles.position,
		Size = UDim2.fromOffset(599, 246),
		AnchorPoint = Vector2.new(0.5, 0.5),
	}, {

		claim = e(Button, {
			fontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Bold,
				Enum.FontStyle.Normal
			),
			text = "Claim",
			textColor3 = Color3.fromRGB(0, 54, 25),
			anchorPoint = Vector2.new(0.5, 0.5),
			textSize = 25,
			size = UDim2.fromOffset(280, 64),
			position = UDim2.fromScale(0.498, 0.634),
			strokeThickness = 1.5,
			layoutOrder = 1,
			applyStrokeMode = Enum.ApplyStrokeMode.Border,
			strokeColor = Color3.fromRGB(0, 0, 0),
			cornerRadius = UDim.new(0, 5),
			gradient = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(68, 252, 153)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(35, 203, 112)),
			}),
			gradientRotation = -90,
			onActivated = function()
				setCrateItemId(nil)
				-- move camera back to player
				CurrentCamera.CameraType = Enum.CameraType.Custom
				CurrentCamera.CameraSubject = (Players.LocalPlayer.Character :: Model):FindFirstChildOfClass("Humanoid")
				if currentCleaner.current then
					currentCleaner.current()
				end
			end,
		}),

		itemName = crateItem and e("TextLabel", {
			FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Bold,
				Enum.FontStyle.Normal
			),
			Text = crateItem.Name,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 35,
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.0573, 0.143),
			Size = UDim2.fromScale(0.884, 0.204),
		}, {
			uIStroke = e("UIStroke"),
		}),

		rarityType = crateItem and e("TextLabel", {
			FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Bold,
				Enum.FontStyle.Normal
			),
			Text = crateItem.Rarity,
			TextColor3 = Rarities[crateItem.Rarity :: Types.ItemRarity].Color,
			TextSize = 32,
			TextYAlignment = Enum.TextYAlignment.Top,
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.0573, 0.322),
			Size = UDim2.fromScale(0.884, 0.179),
		}, {
			uIStroke1 = e("UIStroke"),
		}),
	})
end

return CrateClaim
