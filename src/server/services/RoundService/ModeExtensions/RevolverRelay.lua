--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Services = ServerScriptService.services

local Actions = require(ReplicatedStorage.ecs.actions)
local Components = require(ReplicatedStorage.ecs.components)
local Generic = require(script.Parent.Parent.Generic)
local InventoryService = require(Services.InventoryService)
local InventoryUtils = require(ReplicatedStorage.utils.InventoryUtils)
local Items = require(ReplicatedStorage.constants.Items)
local Janitor = require(ReplicatedStorage.packages.Janitor)
local Matter = require(ReplicatedStorage.packages.Matter)
local RoundService = require(Services.RoundService)
local Sift = require(ReplicatedStorage.packages.Sift)
local Types = require(ReplicatedStorage.constants.Types)

local RevolverRelayExtension = {
	Data = RoundService:GetRoundModeData("Revolver Relay"),
}

function RevolverRelayExtension.StartMatch(Match: Types.Match, RoundInstance: Types.Round, World: Matter.World)
	Generic.StartMatch(Match, RoundInstance, World, false)

	local shiftedPlayersInMatch = Sift.Array.shuffle(RoundService:GetAllPlayersInMatch(Match))
	local relayPlayerGunId = nil
	local relayJanitor = Janitor.new()

	local function giveGunToPlayer(player: Player)
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
				Components.Gun(gunToUse.GunStatisticalData),
				Components.Owner({
					OwnedBy = plrComponent and plrComponent.player,
				}),
				Components.Item({ Id = gunToUse.Id }),
				Components.Parent({ id = entityId }),
				Components.Children({ children = {} })
			)

			relayPlayerGunId = gunId

			newChildren.gunEntityId = gunId
			World:insert(entityId, Components.Children({ children = newChildren }))
		else
			gunId = childComp.children.gunEntityId

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

	local currentRelayIndex = 1
	local relayPlayerHitMap = {} :: { [number]: boolean } -- maps bullet id to whether it hit anyone before expiring

	giveGunToPlayer(shiftedPlayersInMatch[currentRelayIndex])

	-- @note: we probably should check bullethit action afterprocess to mark if the bullet hit someone. then in the task.delay, we can check for this flag.
	local changeRelay = function(_world, player: Player, actionPayload: any)
		local currentRelayPlayer = shiftedPlayersInMatch[currentRelayIndex]
		if player == currentRelayPlayer then
			local spawnedBulletEntityId = actionPayload.spawnedBullet
			local gun: Components.Gun = World:get(actionPayload.fromGun, Components.Gun)
			task.delay(gun.LocalCooldownMillis / 1000, function()
				if not relayPlayerHitMap[spawnedBulletEntityId] then
					if Janitor.Is(relayJanitor) then
						relayJanitor:Cleanup()

						currentRelayIndex = currentRelayIndex + 1
						if currentRelayIndex > #shiftedPlayersInMatch then
							currentRelayIndex = 1
						end

						giveGunToPlayer(shiftedPlayersInMatch[currentRelayIndex])
					end
				end
			end)
		end
	end

	local checkBulletHit = function(_world, player: Player, actionPayload: any)
		local currentRelayPlayer = shiftedPlayersInMatch[currentRelayIndex]
		if player == currentRelayPlayer then
			local targetEntityId = actionPayload.targetEntityId

			local targetHealth: Components.Health? = World:get(targetEntityId, Components.Health)

			if targetHealth and targetHealth.causedBy == relayPlayerGunId then -- our relay player's bullet hit someone
				relayPlayerHitMap[targetHealth.bulletId] = true
			end
		end
	end

	table.insert(Actions.Shoot.afterProcess, changeRelay)
	table.insert(Actions.BulletHit.afterProcess, checkBulletHit)

	Generic.MatchFinishedPromise(Match):andThen(function()
		table.remove(Actions.Shoot.afterProcess, table.find(Actions.Shoot.afterProcess, changeRelay))
		table.remove(Actions.BulletHit.afterProcess, table.find(Actions.BulletHit.afterProcess, checkBulletHit))
		relayJanitor:Destroy()
	end)
end

return RevolverRelayExtension
