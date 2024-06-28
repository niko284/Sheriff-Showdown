local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ServerPackages = ServerScriptService.ServerPackages
local Packages = ReplicatedStorage.packages

local Lapis = require(ServerPackages.Lapis)
local Migrations = require(script.Migrations)
local Signal = require(Packages.Signal)
local t = require(Packages.t)

local collectionName = "PlayerData3" --RunService:IsStudio() and "PlayerData" .. HttpService:GenerateGUID(false) or "PlayerData1"

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
	}),
	migrations = Migrations,
})

local PlayerDataService =
	{ Name = "PlayerDataService", Documents = {}, DocumentLoaded = Signal.new(), BeforeDocumentCloseCallbacks = {} }

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

function PlayerDataService:GetDocument(Player: Player)
	return PlayerDataService.Documents[Player]
end

function PlayerDataService:CloseDocument(Player: Player)
	local document = PlayerDataService.Documents[Player]
	if document ~= nil then
		PlayerDataService.Documents[Player] = nil
		document:close():catch(warn)
	end
end

return PlayerDataService
