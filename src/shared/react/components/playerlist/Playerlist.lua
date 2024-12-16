--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Components = ReplicatedStorage.react.components
local PlayerScripts = LocalPlayer.PlayerScripts
local Constants = ReplicatedStorage.constants

local AutomaticScrollingFrame = require(Components.frames.AutomaticScrollingFrame)
local ClientComm = require(PlayerScripts.ClientComm)
local PlayerlistTemplate = require(Components.playerlist.PlayerlistTemplate)
local React = require(ReplicatedStorage.packages.React)
local Types = require(Constants.Types)

local PlayerlistProperty = ClientComm:GetProperty("ReplicatedPlayerList")

local e = React.createElement
local useEffect = React.useEffect
local useState = React.useState

type PlayerlistProps = {}

local function Playerlist(_props: PlayerlistProps)
	local playerListData: { Types.PlayerlistPlayer }, setPlayerListData = useState({})

	local playerTemplates = {}

	useEffect(function()
		local connection = PlayerlistProperty:Observe(function(newPlayerListData)
			setPlayerListData(newPlayerListData)
		end)

		return function()
			connection:Disconnect()
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
		Position = UDim2.fromScale(0.92, 0.2),
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
