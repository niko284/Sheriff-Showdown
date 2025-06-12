--!strict

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Assets = ReplicatedStorage:FindFirstChild("assets") :: Folder

local AudioUtils = require("@utilities/AudioUtils")
local ClientComm = require("../ClientComm")
local Distractions = require("@constants/Distractions")
local KeybindInputController = require("@controllers/KeybindInputController")
local Net = require("@packages/Net")
local Remotes = require("@network/Remotes")
local Signal = require("@packages/Signal")
local Types = require("@constants/Types")

local RoundNamespace = Remotes.Client:GetNamespace("Round")
local StartMatch = RoundNamespace:Get("StartMatch") :: Net.ClientListenerEvent
local EndMatch = RoundNamespace:Get("EndMatch") :: Net.ClientListenerEvent
local SendDistraction = RoundNamespace:Get("SendDistraction") :: Net.ClientListenerEvent
local VotingPoolClient = ClientComm:GetProperty("VotingPoolClient")
local RoundStatus = ClientComm:GetProperty("RoundStatus")

local DISTRACTION_SIGNS = Assets:FindFirstChild("distractions") :: Folder
local CROSSHAIR_ICON = "rbxassetid://16896087891"

-- // Controller \\

local RoundController = {
	Name = "RoundController",
	StartVoting = Signal.new() :: Signal.Signal<Types.VotingPoolClient>,
	EndVoting = Signal.new(),
	DistractionReceived = Signal.new() :: Signal.Signal<Types.Distraction>,
	StartMatch = Signal.new() :: Signal.Signal<number>,
}

function RoundController:OnStart()
	StartMatch:Connect(function()
		KeybindInputController:SetMouseIcon(CROSSHAIR_ICON)
	end)
	EndMatch:Connect(function()
		KeybindInputController:SetMouseIcon("")

		-- clear any team indicators
		for _, teamIndicator in CollectionService:GetTagged("TeamIndicator") do
			teamIndicator:Destroy()
		end
	end)
	SendDistraction:Connect(function(Distraction: Types.Distraction)
		RoundController.DistractionReceived:Fire(Distraction) -- trigger the DistractionViewport component to show the sign for the distraction

		-- play the distraction audio
		local distractionInfo = Distractions[Distraction]
		if distractionInfo and distractionInfo.AudioId then
			AudioUtils.PlaySoundOnInstance(distractionInfo.AudioId, SoundService)
		end
	end)
	VotingPoolClient:Observe(function(VotingPool: Types.VotingPoolClient)
		if VotingPool then
			RoundController.StartVoting:Fire(VotingPool)
		else
			RoundController.EndVoting:Fire()
		end
	end)
end

function RoundController:ObserveStatusChanged(callback: (string, boolean) -> ())
	return RoundStatus:Observe(function(currStatus: string?)
		if currStatus then
			callback(currStatus, true)
		end
	end)
end

function RoundController:ObserveVotingStarted(callback: (Types.VotingPoolClient) -> ())
	local pool = VotingPoolClient:Get()
	if pool then
		callback(pool)
	end
	return VotingPoolClient.Changed:Connect(callback)
end

function RoundController:ShowDistraction(Distraction: Types.Distraction)
	local signModel = DISTRACTION_SIGNS:FindFirstChild(Distraction) :: Model
	local sign = signModel:Clone()
	sign.Parent = workspace
end

return RoundController
