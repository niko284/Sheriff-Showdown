--!strict

local jecs = require("@packages/jecs")

local Actions = require("@ecs/actions")
local Components = require("@ecs/components")
local Generic = require("../Generic")
local InventoryService = require("@services/InventoryService")
local InventoryUtils = require("@utilities/InventoryUtils")
local Items = require("@constants/Items")
local Janitor = require("@packages/Janitor")
local RoundService = require("@services/RoundService")
local Sift = require("@packages/Sift")
local Timer = require("@packages/Timer")
local Types = require("@constants/Types")

local HOT_POTATO_TIMER = 10

local HotPotatoExtension = {
	Data = RoundService:GetRoundModeData("Hot Potato"),
} :: Types.RoundModeExtension

function HotPotatoExtension.StartMatch(Match: Types.Match, RoundInstance: Types.Round, World: jecs.World)
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
		local childComp: Components.Children? = World:get(entityId, Components.Children)
		local gunId = nil

		if not childComp or not childComp.gunEntityId then
			local newChildren: Components.Children = childComp and table.clone(childComp) or {}

			local gunToUse = Items[2]

			if plrComponent then
				local inventory = InventoryService:GetInventory(plrComponent.player)
				local equippedGuns = InventoryUtils.GetItemsOfType(inventory, "Gun", true)
				if #equippedGuns > 0 then
					gunToUse = equippedGuns[1] :: any
				end
			end

			gunId = World:entity()
			World:set(gunId, Components.Gun, Sift.Dictionary.merge(gunToUse.GunStatisticalData or {}, {
				Damage = 0,
				CriticalDamage = {},
			}))
			World:set(gunId, Components.Owner, { OwnedBy = plrComponent and plrComponent.player })
			World:set(gunId, Components.Item, { Id = gunToUse.Id })
			World:add(gunId, jecs.pair(jecs.ChildOf, entityId))
			World:set(gunId, Components.Children, {})

			lastGunId = relayPlayerGunId
			relayPlayerGunId = gunId

			newChildren.gunEntityId = gunId
			World:set(entityId, Components.Children, newChildren)
		else
			gunId = childComp.gunEntityId

			lastGunId = relayPlayerGunId
			relayPlayerGunId = gunId

			local gun = World:get(gunId, Components.Gun)
			if gun then
				World:set(gunId, Components.Gun, {
					LocalCooldownMillis = gun.LocalCooldownMillis,
					ReloadTimeMillis = gun.ReloadTimeMillis,
					Damage = gun.Damage,
					CriticalDamage = gun.CriticalDamage,
					BulletLifeTime = gun.BulletLifeTime,
					MaxCapacity = gun.MaxCapacity,
					ReloadTime = gun.ReloadTime,
					CurrentCapacity = gun.CurrentCapacity,
					BulletSpeed = gun.BulletSpeed,
					BulletSoundId = gun.BulletSoundId,
					KnockStrength = gun.KnockStrength,
					Disabled = false,
					Reloading = gun.Reloading,
				})
			end
		end

		relayJanitor:Add(function()
			local gun = World:get(gunId, Components.Gun)
			if gun then
				World:set(gunId, Components.Gun, {
					LocalCooldownMillis = gun.LocalCooldownMillis,
					ReloadTimeMillis = gun.ReloadTimeMillis,
					Damage = gun.Damage,
					CriticalDamage = gun.CriticalDamage,
					BulletLifeTime = gun.BulletLifeTime,
					MaxCapacity = gun.MaxCapacity,
					ReloadTime = gun.ReloadTime,
					CurrentCapacity = gun.CurrentCapacity,
					BulletSpeed = gun.BulletSpeed,
					BulletSoundId = gun.BulletSoundId,
					KnockStrength = gun.KnockStrength,
					Disabled = true,
					Reloading = gun.Reloading,
				})
			end
		end)
	end

	giveGunToPlayer(currentPlayer)

	local checkBulletHit = function(_world, player: Player, actionPayload: any)
		if player == currentPlayer then
			local targetEntityId = actionPayload.targetEntityId
			local targetHealth: Components.Health? = World:get(targetEntityId, Components.Health)

			if targetHealth and targetHealth.causedBy == relayPlayerGunId then
				local targetPlayerComp: Components.PlayerComponent? = World:get(targetEntityId, Components.Player)
				if targetPlayerComp then
					relayJanitor:Cleanup()
					giveGunToPlayer(targetPlayerComp.player)
					currentPlayer = targetPlayerComp.player
				end
			end
		end
	end

	local hotPotatoTimer = Timer.new(HOT_POTATO_TIMER)

	hotPotatoTimer.Tick:Connect(function()
		if not currentPlayer then
			return
		end
		local entityId = RoundService:GetEntityIdFromPlayer(currentPlayer)
		if entityId and World:contains(entityId) then
			World:set(entityId, Components.Killed, {
				killerEntityId = lastGunId or relayPlayerGunId,
				expiry = os.time() + 6,
				processRemoval = false,
			})

			table.remove(shiftedPlayersInMatch, table.find(shiftedPlayersInMatch, currentPlayer))

			if #shiftedPlayersInMatch > 1 then
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

	table.insert(Actions.ProjectileHit.afterProcess, checkBulletHit)

	Generic.MatchFinishedPromise(Match):andThen(function()
		table.remove(Actions.ProjectileHit.afterProcess, table.find(Actions.ProjectileHit.afterProcess, checkBulletHit))
		relayJanitor:Destroy()
		hotPotatoTimer:Destroy()
	end)
end

return HotPotatoExtension
