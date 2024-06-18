--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Services = ServerScriptService.services
local Constants = ReplicatedStorage.constants

local PlayerDataService = require(Services.PlayerDataService)
local ResourceService = require(Services.ResourceService)
local ServerComm = require(ServerScriptService.ServerComm)
local Types = require(Constants.Types)

-- // Service Variables \\

local PlayerlistService = {
	Name = "PlayerlistService",
	ReplicatedPlayerList = ServerComm:CreateProperty("ReplicatedPlayerList", {}),
	PlayerList = {},
}

-- // Functions \\

function PlayerlistService:OnInit()
	PlayerDataService.DocumentLoaded:Connect(function(Player, Document)
		local documentData = Document:read()
		local playerData: Types.PlayerlistPlayer = {
			Player = Player,
			Level = documentData.Resources.Level,
		}
		PlayerlistService:AddPlayerToList(playerData)
	end)
end

function PlayerlistService:Start()
	ResourceService:ObserveResourceChanged("Level", function(Player: Player, Level: number)
		PlayerlistService:UpdatePlayerLevel(Player, Level)
	end)
end

function PlayerlistService:OnPlayerRemoving(Player: Player)
	PlayerlistService:RemovePlayerFromList(Player)
end

function PlayerlistService:AddPlayerToList(PlayerListData: Types.PlayerlistPlayer): ()
	table.insert(PlayerlistService.PlayerList, PlayerListData)
	PlayerlistService.ReplicatedPlayerList:Set(PlayerlistService.PlayerList)
end

function PlayerlistService:RemovePlayerFromList(Player: Player): ()
	for Index, PlayerData in PlayerlistService.PlayerList do
		if PlayerData.Player.UserId == Player.UserId then
			table.remove(PlayerlistService.PlayerList, Index)
			PlayerlistService.ReplicatedPlayerList:Set(PlayerlistService.PlayerList)
			break
		end
	end
end

function PlayerlistService:UpdatePlayerLevel(Player: Player, Level: number): ()
	for _, PlayerData in PlayerlistService.PlayerList do
		if PlayerData.Player.UserId == Player.UserId then
			PlayerData.Level = Level
			PlayerlistService.ReplicatedPlayerList:Set(PlayerlistService.PlayerList)
			break
		end
	end
end

return PlayerlistService
