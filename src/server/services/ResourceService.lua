--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Services = ServerScriptService.services
local Packages = ReplicatedStorage.packages

local PlayerDataService = require(Services.PlayerDataService)
local Schema = require(Services.PlayerDataService.Schema)
local Sift = require(Packages.Sift)
local Signal = require(Packages.Signal)

local ResourceService = { Name = "ResourceService", ResourceSignals = {} :: { [string]: Signal.Signal<Player, any> } }

function ResourceService:OnInit()
	for ResourceName, _ in pairs(Schema.Resources) do
		ResourceService.ResourceSignals[ResourceName] = Signal.new()
	end
end

function ResourceService:SetResource(Player: Player, Resource: string, Value: any): ()
	local document = PlayerDataService:GetDocument(Player)
	local newData = table.clone(document:read())
	newData.Resources = Sift.Dictionary.set(newData.Resources, Resource, Value)
	document:write(newData)
end

function ResourceService:GetResource(Player: Player, Resource: string): any
	local document = PlayerDataService:GetDocument(Player)
	local data = document:read()
	return data.Resources[Resource]
end

function ResourceService:ObserveResourceChanged(
	ResourceName: string,
	Callback: (Player, ...any) -> ()
): Signal.Connection
	-- fire signal for plrs who are already in game.
	local resourceSignal = ResourceService.ResourceSignals[ResourceName]
	for _, Player in Players:GetPlayers() do
		local playerDocument = PlayerDataService:GetDocument(Player)
		if playerDocument then
			local documentData = playerDocument:read()
			Callback(Player, documentData.Resources[ResourceName])
		end
	end
	return resourceSignal:Connect(Callback)
end

return ResourceService
