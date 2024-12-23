--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local Constants = ReplicatedStorage.constants
local Services = ServerScriptService.services
local Packages = ReplicatedStorage.packages

local Components = require(ReplicatedStorage.ecs.components)
local InventoryService = require(Services.InventoryService)
local InventoryUtils = require(ReplicatedStorage.utils.InventoryUtils)
local Items = require(Constants.Items)
local Matter = require(Packages.Matter)
local Net = require(Packages.Net)
local Promise = require(Packages.Promise)
local Remotes = require(ReplicatedStorage.network.Remotes)
local RoundService = require(Services.RoundService)
local StatusService = require(Services.StatusService)
local Types = require(Constants.Types)

local RoundNamespace = Remotes.Server:GetNamespace("Round")
local EndMatchClient = RoundNamespace:Get("EndMatch") :: Net.ServerSenderEvent

local START_TIME_SECONDS = 8

-- Generic functions that are used in our Round Service, particularly our mode extensions.
local Generic = {}

function Generic.StartMatch(Match: Types.Match, _RoundInstance: Types.Round, World: Matter.World, equipGuns: boolean?)
	local START_MATCH_TIMESTAMP = os.time() + START_TIME_SECONDS
	RoundService.StartMatchTimestamp:Set(START_MATCH_TIMESTAMP)

	repeat
		RunService.Heartbeat:Wait()
	until os.time() >= START_MATCH_TIMESTAMP

	-- start the match by inserting our equipped guns into the world and assigning our players to the teams.
	for _, team in Match.Teams do
		for _, entityId in team.Entities do
			local target = World:get(entityId, Components.Target)

			if equipGuns ~= false then
				local plrComponent: Components.PlayerComponent? = World:get(entityId, Components.Player)
				local childrenComp: Components.Children<Types.TargetChildren> = World:get(entityId, Components.Children)

				local newChildren = childrenComp and table.clone(childrenComp.children or {})

				local gunToUse = Items[2] -- default gun if nothing is equipped

				if plrComponent then
					local inventory = InventoryService:GetInventory(plrComponent.player)
					local equippedGuns = InventoryUtils.GetItemsOfType(inventory, "Gun", true)
					if #equippedGuns > 0 then
						gunToUse = equippedGuns[1] :: any
					end
				end

				local gunId = World:spawn(
					Components.Gun(gunToUse.GunStatisticalData),
					Components.Owner({
						OwnedBy = plrComponent and plrComponent.player,
					}),
					Components.Item({ Id = gunToUse.Id }),
					Components.Parent({ id = entityId }),
					Components.Children({ children = {} })
				)
				newChildren.gunEntityId = gunId

				World:insert(entityId, childrenComp:patch({ children = newChildren }))
			end

			World:insert(entityId, target:patch({ CanTarget = true }))
			World:insert(entityId, Components.Team({ name = team.Name }))
		end
	end

	local statusProcessedConnection
	statusProcessedConnection = StatusService.StatusProcessed:Connect(function(EntityId: number, Status: Types.Status)
		local renderable: Components.Renderable<Model> = World:get(EntityId, Components.Renderable)
		if Status == "Killed" and renderable then
			for _, team in Match.Teams do
				local isInTeam = table.find(team.Entities, EntityId)
				if isInTeam then
					table.insert(team.Killed, EntityId)

					local target = World:get(EntityId, Components.Target)
					local playerComponent: Components.PlayerComponent? = World:get(EntityId, Components.Player)

					if target then
						World:insert(EntityId, target:patch({ CanTarget = false }))
					end
					World:insert(EntityId, Components.Children({ children = {} }))

					if playerComponent then
						EndMatchClient:SendToPlayer(playerComponent.player)
					end

					local winningTeam = RoundService:GetWinningTeam(Match)
					if winningTeam then
						RoundService.MatchFinished:Fire(Match.MatchUUID, winningTeam)
						statusProcessedConnection:Disconnect()
					end
				end
			end
		end
	end)
end

function Generic.MatchFinishedPromise(Match: Types.Match)
	return Promise.fromEvent(RoundService.MatchFinished, function(MatchUUID: string, _WinningTeam: Types.Team)
		return MatchUUID == Match.MatchUUID
	end)
end

return Generic
