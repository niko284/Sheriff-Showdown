local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Lapis = require("@ServerPackages/Lapis")
local Migrations = require("@self/Migrations")
local Promise = require("@packages/Promise")
local Signal = require("@packages/Signal")
local Types = require("@constants/Types")
local t = require("@packages/t")

local collectionName = RunService:IsStudio() and "PlayerData" .. HttpService:GenerateGUID(false)
	or "SheriffShowdownData123"

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
			ActiveAchievements = t.array(t.interface({
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
		ReceiptHistory = t.array(t.string),
		GiftedGamepasses = t.array(t.number),
	}),
	migrations = Migrations,
})

type PlayerDocument = Lapis.Document<Types.DataSchema>
export type Document = PlayerDocument

local PlayerDataService = {
	Name = "PlayerDataService",
	Documents = {} :: { [Player]: PlayerDocument },
	DocumentLoaded = Signal.new() :: Signal.Signal<Player, PlayerDocument>,
	DocumentClosed = Signal.new() :: Signal.Signal<Player>,
	BeforeDocumentCloseCallbacks = {} :: { (Player) -> () },
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

function PlayerDataService:AwaitDocument(Player: Player)
	local playerDocument = PlayerDataService:GetDocument(Player)
	if playerDocument then
		return Promise.resolve(playerDocument)
	else
		return Promise.race({
			Promise.fromEvent(PlayerDataService.DocumentLoaded, function(loadedPlayer: Player)
				return loadedPlayer.UserId == Player.UserId
			end):andThen(function(_, document: PlayerDocument)
				return document
			end),
			Promise.fromEvent(PlayerDataService.DocumentClosed, function(loadedPlayer: Player)
				return loadedPlayer.UserId == Player.UserId
			end):andThen(function()
				return Promise.reject("Player document closed.")
			end),
		})
	end
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
		PlayerDataService.DocumentClosed:Fire(Player)
		document:close():catch(warn)
	end
end

return PlayerDataService
