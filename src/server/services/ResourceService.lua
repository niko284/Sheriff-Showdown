--!strict

-- Resource Service
-- February 25th, 2022
-- Nick

-- // Variables \\

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Packages = ReplicatedStorage.packages
local Services = ServerScriptService.services

local DataService = require(Services.DataService)
local ProfileSchema = require(ServerScriptService.services.DataService.ProfileSchema)
local ServerComm = require(ServerScriptService.ServerComm)
local Sift = require(Packages.Sift)
local Signal = require(Packages.Signal)

local ResourceTemplate = ProfileSchema.Resources

-- // Service Variables \\

local ResourceService = {
	Name = "ResourceService",
	PlayerResources = ServerComm:CreateProperty("PlayerResources", nil),
	ResourceSignals = {},
}

for ResourceName, _ in pairs(ResourceTemplate) do
	ResourceService.ResourceSignals[ResourceName] = Signal.new()
end

-- // Functions \\

function ResourceService:Init()
	DataService.PlayerDataLoaded:Connect(function(Player: Player, PlayerProfile: DataService.PlayerProfile)
		local Resources = PlayerProfile.Data.Resources
		for ResourceName, _ in pairs(ResourceTemplate) do
			self.ResourceSignals[ResourceName]:Fire(Player, Resources[ResourceName])
		end
		self.PlayerResources:SetFor(Player, Resources)
	end)
end

function ResourceService:SetResource(Player: Player, ResourceName: string, Value: any, sendNetworkEvent: boolean?)
	local playerProfile = DataService:GetData(Player)
	if playerProfile then
		local oldValue = playerProfile.Data.Resources[ResourceName]
		playerProfile.Data.Resources = Sift.Dictionary.set(playerProfile.Data.Resources, ResourceName, Value)
		self.ResourceSignals[ResourceName]:Fire(Player, Value, oldValue)
		if sendNetworkEvent ~= false then
			self.PlayerResources:SetFor(Player, {
				[ResourceName] = Value,
			})
		end
	end
end

function ResourceService:InsertResource(Player: Player, ResourceName: string, Value: any)
	local playerProfile = DataService:GetData(Player)
	if playerProfile then
		playerProfile.Data.Resources = Sift.Dictionary.set(
			playerProfile.Data.Resources,
			ResourceName,
			Sift.Array.push(playerProfile.Data.Resources[ResourceName], Value)
		)
		self.ResourceSignals[ResourceName]:Fire(Player, playerProfile.Data.Resources[ResourceName])
		self.PlayerResources:SetFor(Player, {
			[ResourceName] = playerProfile.Data.Resources[ResourceName],
		})
	end
end

function ResourceService:IncrementResource(
	Player: Player,
	ResourceName: string,
	Value: number,
	sendNetworkEvent: boolean?
)
	local playerProfile = DataService:GetData(Player)
	if playerProfile then
		local oldValue = playerProfile.Data.Resources[ResourceName]
		playerProfile.Data.Resources = Sift.Dictionary.set(
			playerProfile.Data.Resources,
			ResourceName,
			Value + playerProfile.Data.Resources[ResourceName]
		)
		self.ResourceSignals[ResourceName]:Fire(Player, playerProfile.Data.Resources[ResourceName], oldValue)
		if sendNetworkEvent ~= false then
			self.PlayerResources:SetFor(Player, {
				[ResourceName] = playerProfile.Data.Resources[ResourceName],
			})
		end
	end
end

function ResourceService:GetResource(Player: Player, ResourceName: string): any
	local playerProfile = DataService:GetData(Player)
	if not playerProfile then
		return nil
	else
		return playerProfile.Data.Resources[ResourceName]
	end
end

function ResourceService:ObserveResourceChanged(
	ResourceName: string,
	Callback: (Player, ...any) -> ()
): Signal.Connection
	-- fire signal for plrs who are already in game.
	local resourceSignal = ResourceService.ResourceSignals[ResourceName]
	for _, Player in Players:GetPlayers() do
		local playerProfile = DataService:GetData(Player)
		if playerProfile then
			Callback(Player, playerProfile.Data.Resources[ResourceName])
		end
	end
	return resourceSignal:Connect(Callback)
end

return ResourceService
