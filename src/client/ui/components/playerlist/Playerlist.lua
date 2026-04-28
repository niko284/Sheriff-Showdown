--!strict

local UserInputService = game:GetService("UserInputService")

local AutomaticScrollingFrame = require("@ui/components/frames/AutomaticScrollingFrame")
local BlinkClient = require("@client/modules/BlinkClient")
local CurrentInterfaceContext = require("@ui/contexts/CurrentInterfaceContext")
local PlayerlistTemplate = require("@ui/components/playerlist/PlayerlistTemplate")
local React = require("@packages/React")
local ReactSpring = require("@packages/ReactSpring")
local Types = require("@constants/Types")

local e = React.createElement
local useEffect = React.useEffect
local useState = React.useState
local useContext = React.useContext

type PlayerlistProps = {}

local function Playerlist(_props: PlayerlistProps)
	local playerListData: { Types.PlayerlistPlayer }, setPlayerListData = useState({})
	local isOpened, setIsOpened = useState(true)

	local currentInterfaceContext = useContext(CurrentInterfaceContext)

	local styles = ReactSpring.useSpring({
		position = (currentInterfaceContext.hideHUD or not isOpened) and UDim2.fromScale(1.4, 0.2)
			or UDim2.fromScale(0.92, 0.2),
	}, { currentInterfaceContext.hideHUD, isOpened })

	local playerTemplates = {}

	useEffect(function()
		local disconnect = BlinkClient.PlayerlistSync.On(function(newPlayerListData)
			setPlayerListData(newPlayerListData)
		end)

		local toggleInput = UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if
				input.KeyCode == Enum.KeyCode.Tab
				and not gameProcessed
				and input.UserInputState == Enum.UserInputState.Begin
			then
				setIsOpened(function(open)
					return not open
				end)
			end
		end)

		return function()
			disconnect()
			toggleInput:Disconnect()
		end
	end, {})

	for _index, player in playerListData do
		playerTemplates[player.Player.UserId] = e(PlayerlistTemplate, {
			player = player.Player,
			level = player.Level,
			size = UDim2.fromOffset(240, 42),
			kills = player.Kills,
			deaths = player.Deaths,
			playTime = player.Playtime,
			longestKillStreak = player.LongestKillStreak,
			wins = player.Wins,
		})
	end

	return e("Frame", {
		BackgroundTransparency = 1,
		Position = styles.position,
		Size = UDim2.fromOffset(246, 449),
		AnchorPoint = Vector2.new(0.5, 0.5),
	}, {
		topbar = e("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(-1, -1),
			Size = UDim2.fromOffset(248, 42),
		}, {
			background = e("ImageLabel", {
				Image = "rbxassetid://17860375137",
				BackgroundTransparency = 1,
				ZIndex = 0,
				Size = UDim2.fromOffset(248, 42),
			}),

			pattern = e("ImageLabel", {
				Image = "rbxassetid://17860375220",
				BackgroundTransparency = 1,
				Size = UDim2.fromOffset(248, 42),
			}),

			name = e("TextLabel", {
				FontFace = Font.new(
					"rbxasset://fonts/families/GothamSSm.json",
					Enum.FontWeight.Medium,
					Enum.FontStyle.Normal
				),
				Text = "Name",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 12,
				TextTransparency = 0.38,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(13, 17),
				Size = UDim2.fromOffset(36, 9),
			}),

			level = e("TextLabel", {
				FontFace = Font.new(
					"rbxasset://fonts/families/GothamSSm.json",
					Enum.FontWeight.Medium,
					Enum.FontStyle.Normal
				),
				Text = "Level",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 12,
				TextTransparency = 0.38,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(202, 17),
				Size = UDim2.fromOffset(30, 9),
			}),
		}),

		scrollingFrame = e(AutomaticScrollingFrame, {
			scrollBarThickness = 5,
			active = true,
			backgroundTransparency = 1,
			borderSizePixel = 0,
			position = UDim2.fromScale(0, 0.107),
			size = UDim2.fromOffset(246, 401),
			anchorPoint = Vector2.new(0, 0),
		}, {
			listLayout = e("UIListLayout", {
				Padding = UDim.new(0, 7),
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),

			list = e(React.Fragment, nil, playerTemplates),

			padding = e("UIPadding", {
				PaddingTop = UDim.new(0, 2),
			}),
		}),
	})
end

return Playerlist
