--!strict

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Assets = ReplicatedStorage:FindFirstChild("assets") :: Folder

local AudioUtils = require("@utilities/AudioUtils")
local BlinkClient = require("@client/modules/BlinkClient")
local Distractions = require("@constants/Distractions")
local KeybindInputController = require("@controllers/KeybindInputController")
local Signal = require("@packages/Signal")
local Types = require("@constants/Types")

local DISTRACTION_SIGNS = Assets:FindFirstChild("distractions") :: Folder
local CROSSHAIR_ICON = "rbxassetid://16896087891"

-- // Controller \\

local RoundController = {
	Name = "RoundController",
	StartVoting = Signal.new() :: Signal.Signal<Types.VotingPoolClient>,
	EndVoting = Signal.new(),
	DistractionReceived = Signal.new() :: Signal.Signal<Types.Distraction>,
	StartMatch = Signal.new() :: Signal.Signal<number>,
	CurrentVotingPool = nil :: Types.VotingPoolClient?,
	CurrentRoundStatus = nil :: string?,
}

function RoundController:OnStart()
	BlinkClient.RoundStartMatch.On(function()
		KeybindInputController:SetMouseIcon(CROSSHAIR_ICON)
	end)
	BlinkClient.RoundEndMatch.On(function()
		KeybindInputController:SetMouseIcon("")

		-- clear any team indicators
		for _, teamIndicator in CollectionService:GetTagged("TeamIndicator") do
			teamIndicator:Destroy()
		end
	end)
	BlinkClient.RoundSendDistraction.On(function(Distraction: Types.Distraction)
		RoundController.DistractionReceived:Fire(Distraction) -- trigger the DistractionViewport component to show the sign for the distraction

		-- play the distraction audio
		local distractionInfo = Distractions[Distraction]
		if distractionInfo and distractionInfo.AudioId then
			AudioUtils.PlaySoundOnInstance(distractionInfo.AudioId, SoundService)
		end
	end)
	BlinkClient.RoundApplyTeamIndicator.On(function(...)
		RoundController.StartMatch:Fire(...)
	end)
	BlinkClient.VotingSync.On(function(VotingPool: Types.VotingPoolClient)
		RoundController.CurrentVotingPool = VotingPool
		if VotingPool then
			RoundController.StartVoting:Fire(VotingPool)
		else
			RoundController.EndVoting:Fire()
		end
	end)
end

function RoundController:ObserveStatusChanged(callback: (string, boolean) -> ())
	return BlinkClient.RoundStatusSync.On(function(currStatus: string?)
		if currStatus then
			RoundController.CurrentRoundStatus = currStatus
			callback(currStatus, true)
		end
	end)
end

function RoundController:ObserveVotingStarted(callback: (Types.VotingPoolClient) -> ())
	local pool = RoundController.CurrentVotingPool
	if pool then
		callback(pool)
	end
	return RoundController.StartVoting:Connect(callback)
end

function RoundController:ShowDistraction(Distraction: Types.Distraction)
	local signModel = DISTRACTION_SIGNS:FindFirstChild(Distraction) :: Model
	local sign = signModel:Clone()
	sign.Parent = workspace
end

return RoundController
