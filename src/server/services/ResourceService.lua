local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Services = ServerScriptService.services
local Packages = ReplicatedStorage.packages

local PlayerDataService = require(Services.PlayerDataService)
local Sift = require(Packages.Sift)

local ResourceService = { Name = "ResourceService" }

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

return ResourceService
