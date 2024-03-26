--!strict
-- Transaction Controller
-- August 25th, 2023
-- Nick

-- // Variables \\

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerScripts = LocalPlayer.PlayerScripts
local Constants = ReplicatedStorage.constants

local Gamepasses = require(Constants.Gamepasses)
local Types = require(Constants.Types)

-- // Controller Variables \\

local TransactionController = {
	Name = "TransactionController",
}

-- // Functions \\

function TransactionController:Init() end

function TransactionController:Start() end

function TransactionController:GetGamepassByName(GamepassName: string): Types.GamepassInfo
	local GamepassInfo = nil
	for _, Gamepass in Gamepasses do
		if Gamepass.Name == GamepassName then
			GamepassInfo = Gamepass
			break
		end
	end
	return GamepassInfo
end

function TransactionController:PromptGamepassPurchase(GamepassName: string)
	local GamepassInfo = TransactionController:GetGamepassByName(GamepassName)
	if GamepassInfo then
		MarketplaceService:PromptGamePassPurchase(LocalPlayer, GamepassInfo.GamepassId)
	end
end

return TransactionController
