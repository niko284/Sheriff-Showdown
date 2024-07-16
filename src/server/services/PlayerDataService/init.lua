local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local ServerPackages = ServerScriptService.ServerPackages
local Packages = ReplicatedStorage.packages

local Lapis = require(ServerPackages.Lapis)
local Migrations = require(script.Migrations)
local Promise = require(Packages.Promise)
local Signal = require(Packages.Signal)
local t = require(Packages.t)

local collectionName = RunService:IsStudio() and "PlayerData" .. HttpService:GenerateGUID(false) or "PlayerData1001"

local PlayerDataCollection = Lapis.createCollection(collectionName, {
	defaultData = require(script.Schema),
	validate = t.strictInterface({
		Inventory = t.strictInterface({
			Storage = t.table,
			Equipped = t.table,
			GrantedDefaults = t.array(t.numberPositive),
		}),
		Resources = t.interface({
			Coins = t.number,
			Gems = t.number,
			Level = t.number,
			Experience = t.number,
		}),
		Statistics = t.interface({}),
		Settings = t.interface({}),
		CodesRedeemed = t.array(t.string),
		ProcessingTrades = t.array(t.strictInterface({
			Giving = t.array(t.any),
			Receiving = t.array(t.any),
			TradeUUID = t.string,
		})),
		Achievements = t.strictInterface({
			LastDailyRotation = t.number,
			ActiveAchievements = t.array(t.strictInterface({
				Id = t.numberPositive,
				TimesClaimed = t.numberMin(0),
				UUID = t.string,
				Claimed = t.boolean,
				Requirements = t.array(t.strictInterface({
					Progress = t.numberMin(0),
					Goal = t.numberMin(1), -- don't want to divide by 0
				})),
			})),
		}),
	}),
	migrations = Migrations,
})

local PlayerDataService = {
	Name = "PlayerDataService",
	Documents = {},
	DocumentLoaded = Signal.new(),
	BeforeDocumentCloseCallbacks = {},
	DataSessionLock = {} :: { [Player]: boolean },
}

function PlayerDataService:OnStart()
	for _, Player in Players:GetPlayers() do
		PlayerDataService:LoadDocument(Player)
	end
	Players.PlayerAdded:Connect(function(Player: Player)
		PlayerDataService:LoadDocument(Player)
	end)
	Players.PlayerRemoving:Connect(function(Player: Player)
		PlayerDataService:CloseDocument(Player)
	end)
end

function PlayerDataService:LoadDocument(Player: Player)
	PlayerDataCollection:load("Player_" .. Player.UserId)
		:andThen(function(document)
			if Player:IsDescendantOf(Players) == false then
				document:close():catch(warn)
				return
			end
			PlayerDataService.Documents[Player] = document

			document:beforeClose(function()
				for _, callback in PlayerDataService.BeforeDocumentCloseCallbacks do
					callback(Player)
				end
			end)

			PlayerDataService.DocumentLoaded:Fire(Player, document)
		end)
		:catch(function(err)
			warn(`Player {Player.Name}'s data failed to load: {err}`)
			Player:Kick("Data failed to load.")
		end)
end

function PlayerDataService:IsSessionLocked(Player: Player): boolean
	return PlayerDataService.DataSessionLock[Player] == true
end

function PlayerDataService:LockSession(Player: Player)
	PlayerDataService.DataSessionLock[Player] = true
	return Promise.resolve()
end

function PlayerDataService:UnlockSession(Player: Player)
	PlayerDataService.DataSessionLock[Player] = nil
	return Promise.resolve()
end

function PlayerDataService:GetDocument(Player: Player)
	return PlayerDataService.Documents[Player]
end

function PlayerDataService:CloseDocument(Player: Player)
	local document = PlayerDataService.Documents[Player]
	if document ~= nil and PlayerDataService:IsSessionLocked(Player) == false then
		PlayerDataService.Documents[Player] = nil
		document:close():catch(warn)
	end
end

return PlayerDataService
