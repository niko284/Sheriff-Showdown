--!strict

-- Killed
-- February 3rd, 2024
-- Nick

-- // Variables \\

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local Utils = ReplicatedStorage.utils
local Constants = ReplicatedStorage.constants
local ActionShared = ReplicatedStorage.ActionShared
local Packages = ReplicatedStorage.packages

local EffectsModule = require(ActionShared.Processes.Effects)
local ItemUtils = require(Utils.ItemUtils)

local Action = require(ActionShared.Action)
local CombatUtils = require(Utils.CombatUtils)
local Janitor = require(Packages.Janitor)
local Types = require(Constants.Types)

local Killed = {
	Data = {
		Name = "Killed",
		DurationMillis = 4000,
		CompatibleStatuses = {},
	},
}

function Killed.Apply(Entity: Types.Entity, Actor: Types.Entity?)
	local ragdollService = require(ServerScriptService.services.RagdollService)
	local inventoryService = require(ServerScriptService.services.InventoryService)

	local cleaner = Janitor.new()

	local isPlayerEntity = Players:GetPlayerFromCharacter(Entity)

	if not isPlayerEntity and Entity:GetAttribute("ImmuneToKnockback") ~= true then -- We knockback AIs on the server since they don't run StatusHandler.ProcessClient
		CombatUtils.Knockback(Actor, Entity)

		-- Keep the ownership of the NPC on the server to avoid any jittering while the NPC is knocked back.
		local keepNetworkOwner = RunService.Heartbeat:Connect(function()
			if not Entity:FindFirstChild("HumanoidRootPart") then
				return
			end
			local canSet = pcall(Entity.HumanoidRootPart.CanSetNetworkOwnership, Entity.HumanoidRootPart)
			if canSet then
				if Entity.HumanoidRootPart.Anchored == false and Entity.HumanoidRootPart:GetNetworkOwner() ~= nil then
					Entity.HumanoidRootPart:SetNetworkOwner(nil)
				end
			end
		end)
		cleaner:Add(keepNetworkOwner, "Disconnect")
	end

	if Entity:GetAttribute("ImmuneToKnockback") ~= true then
		ragdollService:Ragdoll(Entity)
	end

	cleaner:Add(function()
		ragdollService:Unragdoll(Entity)
	end)

	local gunThatKilledEntityId = nil
	if Actor then
		local plrActor = Players:GetPlayerFromCharacter(Actor)
		if plrActor then
			local gun = inventoryService:GetItemsOfType(plrActor, "Gun", true)[1]
			if gun then
				gunThatKilledEntityId = gun.Id
			end
		end
	end

	return true,
		cleaner,
		{ -- the third return value is the data that will be passed to the ProcessStatusFX function (this is optional)
			gunThatKilledEntityId, -- pass the gun id that killed the entity to the client, we may use this for custom kill effects.
		}
end

function Killed.ApplyFX(Entity: Types.Entity, GunEquippedId: number?)
	if GunEquippedId then
		local itemInfo = ItemUtils.GetItemInfoFromId(GunEquippedId)
		local effectInfo = EffectsModule[itemInfo.Name]
		if effectInfo then
			effectInfo.ApplyKillEffect(Entity)
		end
	end
end

function Killed.ProcessClient(Entity: Types.Entity, Actor: Types.Entity?, _Data: any)
	CombatUtils.Knockback(Actor, Entity)
end

function Killed.Process(Entity: Types.Entity, EntityState: Types.EntityState)
	if EntityState and EntityState.LastActionState and EntityState.LastActionState.Interruptable == false then -- this action is not interruptable, so don't cancel it.
		return
	else
		Action.FinishAll(Entity) -- If the entity is stunned, then they can't do anything.
	end
end

function Killed.Clear(Entity: Types.Entity, Cleaner: Types.Janitor)
	if Janitor.Is(Cleaner) then
		Cleaner:Destroy()
	end
	local plr = Players:GetPlayerFromCharacter(Entity)
	if plr then
		plr:LoadCharacter()
	else
		Entity:Destroy()
	end
	return true
end

return Killed
