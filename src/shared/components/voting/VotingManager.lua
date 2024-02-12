-- Voting Manager
-- February 9th, 2024
-- Nick

-- // Variables \\

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerScripts = LocalPlayer.PlayerScripts
local Packages = ReplicatedStorage.packages
local Components = ReplicatedStorage.components
local VotingComponents = Components.voting
local Controllers = PlayerScripts.controllers

local React = require(Packages.React)
local ReactSpring = require(Packages.ReactSpring)
local Remotes = require(ReplicatedStorage.Remotes)
local RoundController = require(Controllers.RoundController)
local VotingTemplate = require(VotingComponents.VotingTemplate)

local RemoteNamespace = Remotes.Client:GetNamespace("Voting")
local ProcessVote = RemoteNamespace:Get("ProcessVote")

local useEffect = React.useEffect
local e = React.createElement
local useState = React.useState
local useCallback = React.useCallback

-- // Voting Manager \\

type VotingManagerProps = {}

local function VotingManager(_props: VotingManagerProps)
	local votingPool, setVotingPool = useState(nil)
	local currentFieldIndex, setCurrentFieldIndex = useState(nil)

	local styles = ReactSpring.useSpring({
		position = (votingPool and currentFieldIndex and currentFieldIndex <= #votingPool.VotingFields and UDim2.fromScale(
			0.5,
			0.2
		)) or UDim2.fromScale(0.5, -1),
	}, { votingPool, currentFieldIndex })

	local onVotingFieldChoiceSelected = useCallback(function(votingField: string, votingChoice: string)
		setCurrentFieldIndex(currentFieldIndex and currentFieldIndex + 1 or 1)

		-- send the choice to the server
		ProcessVote:SendToServer(votingField, votingChoice)

		-- for this voting pool field, we need to send the choice selected to the server for tallying. also, pop up the next voting field if it exists.
	end, { setCurrentFieldIndex, currentFieldIndex })

	useEffect(function()
		local startVotingConnection = RoundController.StartVoting:Connect(function(VotingPoolClient)
			setVotingPool(VotingPoolClient)
			setCurrentFieldIndex(1) -- start at the first field. when a button is clicked on the voting template, it will increment the index
		end)
		local endVotingConnection = RoundController.EndVoting:Connect(function()
			setVotingPool(nil)
			setCurrentFieldIndex(nil)
		end)

		return function()
			startVotingConnection:Disconnect()
			endVotingConnection:Disconnect()
		end
	end, { setVotingPool, setCurrentFieldIndex })

	-- with the voting pool, we can create the voting template components
	local votingComponents = {}

	if votingPool and currentFieldIndex and #votingPool.VotingFields >= currentFieldIndex then
		local votingChoices = votingPool.VotingFields[currentFieldIndex]
		for index, choice in votingChoices.Choices do
			table.insert(
				votingComponents,
				e(VotingTemplate, {
					choice = choice,
					size = UDim2.fromOffset(164, 191),
					layoutOrder = index,
					key = choice,
					field = votingChoices.Field,
					onActivated = onVotingFieldChoiceSelected,
				})
			)
		end
	end

	return e("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.51),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		ZIndex = 2,
		BorderSizePixel = 0,
		Position = styles.position,
		Size = UDim2.fromOffset(583, 257),
	}, {
		title = e("TextLabel", {
			FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
			Text = "Voting",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextScaled = true,
			TextSize = 14,
			TextWrapped = true,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(-2.09e-07, 0.00402),
			Size = UDim2.fromOffset(583, 45),
		}, {
			uICorner = e("UICorner", {
				CornerRadius = UDim.new(0.025, 1),
			}),

			uIStroke = e("UIStroke", {
				Thickness = 2,
				Transparency = 0.8,
			}, {
				uIGradient = e("UIGradient", {
					Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0)),
					}),
					Rotation = -90,
					Transparency = NumberSequence.new({
						NumberSequenceKeypoint.new(0, 0),
						NumberSequenceKeypoint.new(0.498, 1),
						NumberSequenceKeypoint.new(1, 1),
					}),
				}),
			}),
		}),

		uIStroke1 = e("UIStroke", {
			Color = Color3.fromRGB(255, 255, 255),
			Thickness = 3,
			Transparency = 0.3,
		}, {
			uIGradient1 = e("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0)),
				}),
				Rotation = 90,
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0.798),
					NumberSequenceKeypoint.new(0.8, 1),
					NumberSequenceKeypoint.new(1, 1),
				}),
			}),
		}),

		votingList = e("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(255, 0, 0),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.5, 0.589),
			Size = UDim2.fromOffset(582, 209),
		}, {
			listLayout = e("UIListLayout", {
				Padding = UDim.new(0, 10),
				FillDirection = Enum.FillDirection.Horizontal,
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),

			votingButtons = e(React.Fragment, nil, votingComponents),

			uIPadding = e("UIPadding", {
				PaddingLeft = UDim.new(0.06, 0),
			}),
		}),

		uICorner1 = e("UICorner", {
			CornerRadius = UDim.new(0.01, 8),
		}),

		uIGradient2 = e("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(13, 13, 13)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(36, 36, 36)),
			}),
			Rotation = 90,
		}),
	})
end

return VotingManager
