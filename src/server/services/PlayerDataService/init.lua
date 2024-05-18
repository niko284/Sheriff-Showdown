local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ServerPackages = ServerScriptService.ServerPackages
local Packages = ReplicatedStorage.packages

local Lapis = require(ServerPackages.Lapis)
local Signal = require(Packages.Signal)
local t = require(Packages.t)

local PlayerDataCollection = Lapis.createCollection("PlayerData", {
	defaultData = require(script.Schema),
	validate = t.strictInterface({}),
})

local PlayerDataService = { Name = "PlayerDataService", Documents = {}, DocumentLoaded = Signal.new() }

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
		end)
		:catch(function(err)
			warn(`Player {Player.Name}'s data failed to load: {err}`)
			Player:Kick("Data failed to load.")
		end)
end

function PlayerDataService:CloseDocument(Player: Player)
	local document = PlayerDataService.Documents[Player]
	if document ~= nil then
		PlayerDataService.Documents[Player] = nil
		document:close():catch(warn)
	end
end

return PlayerDataService
