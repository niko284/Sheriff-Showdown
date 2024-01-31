--!strict

-- Combat Controller
-- November 17th, 2022
-- Ron

-- // Variables \\

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerScripts = LocalPlayer.PlayerScripts
local Serde = ReplicatedStorage.serde
local Packages = ReplicatedStorage.packages
local Constants = ReplicatedStorage.constants
local Controllers = PlayerScripts.controllers
local ActionShared = ReplicatedStorage.ActionShared
local Rodux = PlayerScripts.rodux
local Utils = ReplicatedStorage.utils

local Action = require(ActionShared.Action)
local ClientComm = require(PlayerScripts.ClientComm)
local EntityModule = require(ActionShared.Entity)
local Handlers = require(ActionShared.Handlers)
local HitFXSerde = require(Serde.HitFXSerde)
local ItemUtils = require(Utils.ItemUtils)
local Janitor = require(Packages.Janitor)
local KeybindInputController = require(Controllers.KeybindInputController)
local Promise = require(Packages.Promise)
local Remotes = require(ReplicatedStorage.Remotes)
local StatusModule = require(ActionShared.StatusModule)
local Types = require(Constants.Types)
local UUIDSerde = require(Serde.UUIDSerde)

local EntityRemotes = Remotes.Client:GetNamespace("Entity")
local ClientReady = EntityRemotes:Get("ClientReady")
local ProcessFX = EntityRemotes:Get("ProcessFX")
local ProcessAction = EntityRemotes:Get("ProcessAction")
local FinishedServer = EntityRemotes:Get("FinishedServer")
local ProcessStatus = EntityRemotes:Get("ProcessStatus")
local CombatToggle = ClientComm:GetProperty("CombatToggle")

local CONTROLS_ENABLED = false

-- // Controller \\

local ActionController = {
	Name = "ActionController",
	PartTransparencies = {},
	Store = nil :: any,
}

-- // Functions \\

function ActionController:Init()
	CombatToggle:Observe(function(Toggle: boolean)
		print(Toggle)
		ActionController:ToggleControls(Toggle)
	end)
	ProcessFX:Connect(function(ActionName: string, FXName: string, Args: Types.VFXArguments)
		Args = HitFXSerde.Deserialize(Args)
		local Handler = Handlers[ActionName]
		local FXFunc = (Handler :: any).Callbacks[FXName] :: (
				Types.VFXArguments,
				(() -> ())?
			) -> (boolean, ((boolean?) -> ())?, RBXScriptSignal?)

		if not FXFunc then
			assert(false, "No FX function found for action " .. ActionName .. " and FX " .. FXName .. ".")
		end

		local Cleaner = Janitor.new()
		local wasFinished = false

		local _success, ToClean, finishedEvent = FXFunc(Args)

		if ToClean then
			Cleaner:Add(function()
				if typeof(ToClean) == "function" then
					if wasFinished then
						ToClean(false)
					elseif wasFinished == false then
						ToClean(true)
					end
				else
					ToClean:Destroy() -- Particularly for things that don't return functions so that they match other schemas.
				end
			end)
		end

		if finishedEvent then
			finishedEvent:Once(function()
				wasFinished = true
				Cleaner:Destroy()
			end)
		else
			wasFinished = true
			Cleaner:Destroy()
		end
	end)

	FinishedServer:Connect(function()
		-- Server told us our action finished, so we can now allow the player to do another action.
		local entity, state = EntityModule.GetEntityAndState(LocalPlayer.Character)
		if entity and state then
			local lastAction = state.LastActionState
			if lastAction then
				lastAction.Finished = true -- Common.ClientWaitForFinished will now finish and fire the Finished event in the action process.
			end
		end
	end)

	ProcessStatus:Connect(function(Status: Types.EntityStatus, ...: any)
		local EntityState = EntityModule.GetState(LocalPlayer.Character)
		local StatusHandler = StatusModule.GetStatusHandler(Status)
		if StatusHandler and StatusHandler.ProcessClient and EntityState then
			StatusHandler.ProcessClient(LocalPlayer.Character, EntityState, ...)
		end
	end)
end

function ActionController:Start()
	ActionController.Store = require(Rodux.Store)
	ClientReady:Connect(function()
		print("Client ready")
		ActionController:BindHandlers()
	end)
	ActionController.Store.changed:connect(function(newState, oldState)
		if newState.Inventory ~= oldState.Inventory then
			ActionController:UnbindAllHandlers()
			ActionController:BindHandlers() -- Something changed in the inventory which may have changed the equipped items and thus the handlers.
		end
	end)
end

function ActionController:PlayAction(Handler: Types.ActionHandler, InputObject: InputObject): boolean
	local Character = LocalPlayer.Character
	local Entity, EntityState = EntityModule.GetEntityAndState(Character)
	-- assert(Entity and EntityState, "Couldn't play action, Entity or EntityState not valid.")

	print("Trying")

	if not Entity or not EntityState then
		return false
	end

	if CONTROLS_ENABLED == false and (Handler.Data.AlwaysOn and not Handler.Data.AlwaysOn() or not Handler.Data.AlwaysOn) then -- although this probably won't run when controls are disabled, it is possible if a player clicks an action on the hotbar.
		return false
	end
	--[[if game.PlaceId == PlaceIds.Lobby and Handler.Data.IsBaseAction ~= true then
		return false -- No abilities in the lobby, except for base actions.
	end--]]

	print("Playing")

	local actionUUID = HttpService:GenerateGUID(false) -- server uses this to identify the action.
	local processArgs, stateInfo = Action.Init(Handler, Entity, actionUUID, InputObject)

	local Verify, DoAction = Action.Run(Handler, Entity, EntityState, processArgs, stateInfo)
	local didResolve, rollbackState, initialServerLoad = Verify():await()

	if didResolve and stateInfo.CancelPreviousAction ~= true then -- if we cancelled the previous action, we dont want to do anything else.
		-- @NOTE: We should come back to this promise.all and make sure it's working as intended.
		local didAction = Promise.all({
			ProcessAction:CallServerAsync(Handler.Data.Name, UUIDSerde.Serialize(actionUUID), initialServerLoad)
				:andThen(function(actionProcessed: boolean)
					return actionProcessed == true or Promise.reject("Server could not verify action.")
				end)
				:catch(function(err: any)
					warn(tostring(err))

					EntityModule.ChangeState(Entity, rollbackState)
					Action.FinishAction(Entity, true)
				end),
			DoAction():andThen(function() end):catch(function(err: any, RollbackState: Types.EntityState)
				warn(tostring(err))
				EntityModule.ChangeState(Entity, RollbackState)
			end) or Promise.resolve(),
		}):catch(function(error: any)
			warn(tostring(error))
		end)

		return didAction
	end

	return didResolve
end

function ActionController:ToggleControls(isEnabled: boolean)
	CONTROLS_ENABLED = isEnabled
end

function ActionController:GetHandlerBinds(
	Handler: Types.ActionHandler
): { Enum.KeyCode | Enum.UserInputType | Enum.SwipeDirection }
	local Binds = {}

	-- Base actions like dodge, grip, heavy, light attack are not associated to inventory items like abilities are.
	if Handler.Data.SettingsData.InputData then
		for _DeviceName, Bind in pairs(Handler.Data.SettingsData.InputData) do
			if typeof(Bind) == "table" then
				for _, keybind in pairs(Bind) do
					table.insert(Binds, keybind)
				end
			elseif Bind then
				table.insert(Binds, Bind)
			end
		end
	end

	return Binds
end

function ActionController:BindHandlers()
	-- Bind base actions

	for _HandlerName, Handler in Handlers do
		ActionController:BindHandler(Handler, ActionController:GetHandlerBinds(Handler))
	end
	-- Bind abilities.
	local inventory = (ActionController.Store):getState().Inventory

	print("binding handlers")
	if not inventory then
		print("r")
		return
	end

	for _, item in inventory.Items do
		local isEquipped = table.find(inventory.Equipped, item.UUID)
		local itemInfo = ItemUtils.GetItemInfoFromId(item.Id) :: Types.ItemInfo
		if not isEquipped or not Handlers[itemInfo.Name :: any] then
			continue
		end
	end
end

function ActionController:BindHandler(
	Handler: Types.ActionHandler,
	Binds: { Enum.KeyCode | Enum.SwipeDirection | Enum.UserInputType }
)
	KeybindInputController:BindAction(
		Handler.Data.SettingsData,
		Binds,
		function(_ActionName: string, _InputState: Enum.UserInputState, InputObject: InputObject)
			if
				CONTROLS_ENABLED == false
				and (Handler.Data.AlwaysOn and not Handler.Data.AlwaysOn() or not Handler.Data.AlwaysOn)
			then
				return
			end
			ActionController:PlayAction(Handler, InputObject)
		end
	)
end

function ActionController:UnbindAllHandlers()
	-- Action.FinishAll(LocalPlayer.Character)
	for _HandlerName, Handler in Handlers do
		if Handler.Data.IsBaseAction then
			continue -- We don't want to unbind base actions even if there are changes in the inventory.
		end
		ActionController:UnbindHandler(Handler)
	end
	print("unbinding")
end

function ActionController:UnbindHandler(Handler: Types.ActionHandler)
	KeybindInputController:UnbindAction(Handler.Data.SettingsData)
end

function ActionController:GetCooldownFinishTime(Item: Types.Item | string)
	local entityState = EntityModule.GetState(LocalPlayer.Character)
	local cooldownFinishTime = nil

	if entityState and entityState.LastActionState then -- If we have an entity state, and we have a last action state, there's likely a cooldown in place.
		local localCooldown = entityState.LastActionState.CooldownFinishTimeMillis
		local globalCooldown = entityState.LastActionState.GlobalCooldownFinishTimeMillis
		local lastActionState = entityState.LastActionState
		local lastAction = lastActionState.ActionHandlerName

		if typeof(Item) == "table" and Item.Id then -- Identify the cooldown finish time given an item.
			local itemInformation = ItemUtils.GetItemInfoFromId(Item.Id) :: Types.ItemInfo

			-- If we have an entity state, we can check if the item is on cooldown.
			if entityState and entityState.LastActionState then
				if
					localCooldown and lastAction == itemInformation.Name
					or ((lastAction == "HeavyAttack" or lastAction == "LightAttack") and itemInformation.Type == "Weapon")
				then
					-- this is mostly for abilities. If the cooldown is for this item, we want to display it as the local cooldown. same for weapons
					cooldownFinishTime = localCooldown
				else
					local previousSameAbility = entityState.ActionHistory[itemInformation.Name :: any]
					if previousSameAbility and globalCooldown < previousSameAbility.CooldownFinishTimeMillis then -- Global cooldown is less than previous local cooldown, set to local cooldown.
						cooldownFinishTime = previousSameAbility.CooldownFinishTimeMillis
					else -- Our global cooldown is greater than our previous local cooldown, set to global cooldown.
						cooldownFinishTime = globalCooldown
					end

					if itemInformation.Type == "Weapon" :: Types.ItemType then
						-- If the item is a weapon, let's check if it's on cooldown from our most previous base attack.
						local prevLightAttack = entityState["LightAttack" :: any]
						local prevHeavyAttack = entityState["HeavyAttack" :: any]
						if
							prevLightAttack
							and (not cooldownFinishTime or prevLightAttack.CooldownFinishTimeMillis > cooldownFinishTime)
						then
							cooldownFinishTime = prevLightAttack.CooldownFinishTimeMillis
						end
						if prevHeavyAttack then
							if not cooldownFinishTime or prevHeavyAttack.CooldownFinishTimeMillis > cooldownFinishTime then
								cooldownFinishTime = prevHeavyAttack.CooldownFinishTimeMillis
							end
						end
					end
				end
			end
		else
			if lastAction == Item then
				cooldownFinishTime = localCooldown
			else
				local previousSameAbility = entityState.ActionHistory[Item :: any]
				if previousSameAbility and globalCooldown < previousSameAbility.CooldownFinishTimeMillis then
					cooldownFinishTime = previousSameAbility.CooldownFinishTimeMillis
				else
					cooldownFinishTime = globalCooldown
				end
			end
		end
	end
	return cooldownFinishTime
end

return ActionController
