--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Hooks = ReplicatedStorage.react.hooks
local Components = ReplicatedStorage.react.components
local PlayerScripts = LocalPlayer.PlayerScripts
local Controllers = PlayerScripts.controllers
local Contexts = ReplicatedStorage.react.contexts

local AutomaticScrollingFrame = require(Components.frames.AutomaticScrollingFrame)
local CloseButton = require(Components.buttons.CloseButton)
local CurrentInterfaceContext = require(Contexts.CurrentInterfaceContext)
local InterfaceController = require(Controllers.InterfaceController)
local Net = require(ReplicatedStorage.packages.Net)
local React = require(ReplicatedStorage.packages.React)
local Remotes = require(ReplicatedStorage.network.Remotes)
local RoundController = require(Controllers.RoundController)
local Types = require(ReplicatedStorage.constants.Types)
local VotingTemplate = require(Components.voting.VotingTemplate)
local animateCurrentInterface = require(Hooks.animateCurrentInterface)

local VotingNamespace = Remotes.Client:GetNamespace("Voting")
local ProcessVote = VotingNamespace:Get("ProcessVote") :: Net.ClientSenderEvent

local useState = React.useState
local useEffect = React.useEffect
local useCallback = React.useCallback
local useContext = React.useContext
local e = React.createElement

type VotingProps = {}
local function Voting(_props: VotingProps)
	local votingPool, setVotingPool = useState(nil :: Types.VotingPoolClient?)
	local currentFieldIndex, setCurrentFieldIndex = useState(nil :: number?)
	local currentInterface = useContext(CurrentInterfaceContext)

	local _shouldRender, styles = animateCurrentInterface("Voting", UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.5, 2))

	local onVotingFieldChoiceSelected = useCallback(function(votingField: string, votingChoice: string)
		setCurrentFieldIndex(currentFieldIndex and (currentFieldIndex :: number + 1) or 1)

		if currentFieldIndex + 1 > #votingPool.VotingFields then
			setVotingPool(nil :: any)
			InterfaceController.InterfaceChanged:Fire(nil)
		end

		-- send the choice to the server
		ProcessVote:SendToServer(votingField, votingChoice)

		-- for this voting pool field, we need to send the choice selected to the server for tallying. also, pop up the next voting field if it exists.
	end, { currentFieldIndex, votingPool } :: { any })

	useEffect(function()
		local startVotingConnection = RoundController.StartVoting:Connect(function(VotingPoolClient)
			InterfaceController.InterfaceChanged:Fire("Voting")
			setVotingPool(VotingPoolClient)
			setCurrentFieldIndex(1) -- start at the first field. when a button is clicked on the voting template, it will increment the index
		end)

		local endVotingConnection = RoundController.EndVoting:Connect(function()
			if currentInterface.current == "Voting" then
				InterfaceController.InterfaceChanged:Fire(nil)
			end
			setVotingPool(nil :: any)
			setCurrentFieldIndex(nil :: any)
		end)

		return function()
			startVotingConnection:Disconnect()
			endVotingConnection:Disconnect()
		end
	end, { currentInterface })

	-- with the voting pool, we can create the voting template components
	local votingComponents = {}

	if votingPool and currentFieldIndex and #votingPool.VotingFields >= currentFieldIndex then
		local votingChoices = votingPool.VotingFields[currentFieldIndex]
		for index, choice in votingChoices.Choices do
			table.insert(
				votingComponents,
				e(VotingTemplate, {
					choice = choice.Name,
					size = UDim2.fromOffset(254, 373),
					layoutOrder = index,
					key = choice.Name .. votingChoices.Field,
					field = votingChoices.Field,
					onActivated = onVotingFieldChoiceSelected,
					background = string.format("rbxassetid://%d", choice.Image or 0),
					amountOfVotes = 0,
				})
			)
		end
	end

	return e("ImageLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Image = "rbxassetid://18250424460",
		BackgroundTransparency = 1,
		Position = styles.position,
		Size = UDim2.fromOffset(849, 609),
	}, {
		separator = e("ImageLabel", {
			Image = "rbxassetid://18250424659",
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(26, 188),
			Size = UDim2.fromOffset(798, 4),
		}),

		voteForMap = e("TextLabel", {
			FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Bold,
				Enum.FontStyle.Normal
			),
			Text = "Vote for a map!",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 22,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(27, 124),
			Size = UDim2.fromOffset(179, 22),
		}),

		topbar = e("ImageLabel", {
			Image = "rbxassetid://18250424775",
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(849, 87),
		}, {
			pattern = e("ImageLabel", {
				Image = "rbxassetid://18250424840",
				BackgroundTransparency = 1,
				Size = UDim2.fromOffset(849, 87),
			}),

			voting = e("TextLabel", {
				FontFace = Font.new(
					"rbxasset://fonts/families/GothamSSm.json",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Normal
				),
				Text = "Voting",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 22,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(63, 34),
				Size = UDim2.fromOffset(76, 23),
			}),

			closeButton = e(CloseButton, {
				position = UDim2.fromOffset(793, 35),
				size = UDim2.fromOffset(42, 42),
				zIndex = 2,
				onActivated = function()
					InterfaceController.InterfaceChanged:Fire(nil)
				end,
			}),

			votingIcon = e("ImageLabel", {
				Image = "rbxassetid://18250436220",
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(23, 31),
				Size = UDim2.fromOffset(27, 27),
			}),
		}),

		description = e("TextLabel", {
			FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.SemiBold,
				Enum.FontStyle.Normal
			),
			Text = "Click on a map to vote.",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 12,
			TextTransparency = 0.663,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(28, 153),
			Size = UDim2.fromOffset(141, 13),
		}),

		list = e(AutomaticScrollingFrame, {
			scrollBarThickness = 5,
			active = true,
			backgroundTransparency = 1,
			borderSizePixel = 0,
			position = UDim2.fromScale(0.0212, 0.333),
			size = UDim2.fromOffset(813, 392),
		}, {
			listLayout = e("UIListLayout", {
				Padding = UDim.new(0, 15),
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),

			votingButtons = e(React.Fragment, nil, votingComponents),

			padding = e("UIPadding", {
				PaddingTop = UDim.new(0, 5),
			}),
		}),
	})
end

return React.memo(Voting)
