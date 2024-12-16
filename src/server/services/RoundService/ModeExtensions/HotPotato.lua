--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Constants = ReplicatedStorage.constants
local Services = ServerScriptService.services

local Actions = require(ReplicatedStorage.ecs.actions)
local Components = require(ReplicatedStorage.ecs.components)
local Generic = require(script.Parent.Parent.Generic)
local InventoryService = require(Services.InventoryService)
local InventoryUtils = require(ReplicatedStorage.utils.InventoryUtils)
local Items = require(Constants.Items)
local Janitor = require(ReplicatedStorage.packages.Janitor)
local Matter = require(ReplicatedStorage.packages.Matter)
local RoundService = require(Services.RoundService)
local Sift = require(ReplicatedStorage.packages.Sift)
local Timer = require(ReplicatedStorage.packages.Timer)
local Types = require(Constants.Types)

local HOT_POTATO_TIMER = 10 -- in seconds

local HotPotatoExtension = {
	Data = RoundService:GetRoundModeData("Hot Potato"),
} :: Types.RoundModeExtension

function HotPotatoExtension.StartMatch(Match: Types.Match, RoundInstance: Types.Round, World: Matter.World)
	Generic.StartMatch(Match, RoundInstance, World, false)

	local shiftedPlayersInMatch = Sift.Array.shuffle(RoundService:GetAllPlayersInMatch(Match))
	local relayPlayerGunId = nil
	local lastGunId = nil

	local relayJanitor = Janitor.new()

	local currentPlayer: Player? = shiftedPlayersInMatch[1]

	local function giveGunToPlayer(player: Player?)
		if not player then
			return
		end
		local entityId = RoundService:GetEntityIdFromPlayer(player)

		local plrComponent: Components.PlayerComponent? = World:get(entityId, Components.Player)

		local childComp = World:get(entityId, Components.Children)

		local gunId = nil

		if not childComp or not childComp.children.gunEntityId then
			local newChildren = childComp and table.clone(childComp.children or {})

			local gunToUse = Items[2] -- default gun if nothing is equipped

			if plrComponent then
				local inventory = InventoryService:GetInventory(plrComponent.player)
				local equippedGuns = InventoryUtils.GetItemsOfType(inventory, "Gun", true)
				if #equippedGuns > 0 then
					gunToUse = equippedGuns[1] :: any
				end
			end

			gunId = World:spawn(
				Components.Gun(Sift.Dictionary.merge(gunToUse.GunStatisticalData or {}, {
					Damage = 0,
					CriticalDamage = {},
				})),
				Components.Owner({
					OwnedBy = plrComponent and plrComponent.player,
				}),
				Components.Item({ Id = gunToUse.Id }),
				Components.Parent({ id = entityId }),
				Components.Children({ children = {} })
			)

			lastGunId = relayPlayerGunId
			relayPlayerGunId = gunId

			newChildren.gunEntityId = gunId
			World:insert(entityId, Components.Children({ children = newChildren }))
		else
			gunId = childComp.children.gunEntityId

			lastGunId = relayPlayerGunId
			relayPlayerGunId = gunId

			local gun = World:get(gunId, Components.Gun)

			World:insert(
				gunId,
				gun:patch({
					Disabled = false,
				})
			)
		end

		relayJanitor:Add(function()
			local gun = World:get(gunId, Components.Gun)
			World:insert(
				gunId,
				gun:patch({
					Disabled = true,
				})
			)
		end)
	end

	giveGunToPlayer(currentPlayer)

	local checkBulletHit = function(_world, player: Player, actionPayload: any)
		if player == currentPlayer then
			local targetEntityId = actionPayload.targetEntityId

			local targetHealth: Components.Health? = World:get(targetEntityId, Components.Health)

			if targetHealth and targetHealth.causedBy == relayPlayerGunId then -- our relay player's bullet hit someone
				-- give the gun to the player that was hit like hot potato
				local targetPlayer: Components.PlayerComponent? = World:get(targetEntityId, Components.Player)
				if targetPlayer then
					relayJanitor:Cleanup()
					giveGunToPlayer(targetPlayer.player)
					currentPlayer = targetPlayer.player
				end
			end
		end
	end

	local hotPotatoTimer = Timer.new(HOT_POTATO_TIMER)

	hotPotatoTimer.Tick:Connect(function()
		-- kill the player with the gun
		if not currentPlayer then
			return
		end
		local entityId = RoundService:GetEntityIdFromPlayer(currentPlayer)
		if entityId and World:contains(entityId) then
			World:insert(
				entityId,
				Components.Killed({
					killerEntityId = lastGunId or relayPlayerGunId, -- we technically died because of the person who shot us last OR we couldn't get rid of the gun if we were the first person to get it
					expiry = os.time() + 6,
					processRemoval = false,
				})
			)

			table.remove(shiftedPlayersInMatch, table.find(shiftedPlayersInMatch, currentPlayer))

			if #shiftedPlayersInMatch > 1 then -- we have more than 1 player left, so give the gun to a random player that hasn't been killed
				relayJanitor:Cleanup()
				local randomPlayer = shiftedPlayersInMatch[math.random(1, #shiftedPlayersInMatch)]
				giveGunToPlayer(randomPlayer)
				currentPlayer = randomPlayer
			else
				currentPlayer = nil
			end
		end
	end)

	hotPotatoTimer:Start()

	table.insert(Actions.BulletHit.afterProcess, checkBulletHit)

	Generic.MatchFinishedPromise(Match):andThen(function()
		print("MATCH FINISHED")
		table.remove(Actions.BulletHit.afterProcess, table.find(Actions.BulletHit.afterProcess, checkBulletHit))
		relayJanitor:Destroy()
		hotPotatoTimer:Destroy()
	end)
end

return HotPotatoExtension
