-- Generic Processes
-- July 25th, 2023
-- Nick

-- // Variables \\

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local Constants = ReplicatedStorage.constants
local Packages = ReplicatedStorage.packages
local Wrappers = ReplicatedStorage.wrappers
local ActionShared = ReplicatedStorage.ActionShared
local Utils = ReplicatedStorage.utils

local AnimationShared = require(Utils.AnimationShared)
local DetectionTypes = require(Constants.DetectionTypes)
local EntityModule = require(ActionShared.Entity)
local Janitor = require(Packages.Janitor)
local Net = require(Packages.Net)
local Signal = require(Packages.Signal)
local StatusModule = require(ActionShared.StatusModule)
local Types = require(Constants.Types)
local withEntityAndState = require(Wrappers.withEntityAndState)

local IS_CLIENT = RunService:IsClient()
local IS_SERVER = RunService:IsServer()
local NPC_TAGS = { "Helper", "Blacksmith", "Shopkeeper" }

-- // Processes \\

local GenericProcesses = {}

function GenericProcesses.Generic(
	ProcessName: string,
	Async: boolean,
	OnServer: boolean,
	OnClient: boolean,
	Delegate: Types.Delegate
)
	return {
		ProcessName = ProcessName,
		Async = Async,
		OnServer = OnServer,
		OnClient = OnClient,
		Delegate = Delegate,
	}
end

function GenericProcesses.ProcessHitGeneric(ProcessTime: number?, MultiHit: boolean?, HitSameEntity: boolean?)
	return {
		ProcessName = "ProcessHit",
		Async = true,
		OnServer = true,
		OnAI = false,
		OnClient = false,
		Delegate = function(ArgPack: Types.ProcessArgs, StateInfo: Types.ActionStateInfo): boolean
			local ProcessHit = ArgPack.Interfaces.Comm.ProcessHit :: Net.ServerListenerEvent
			local StopHits = ArgPack.Interfaces.Comm.StopHits :: Net.ServerListenerEvent
			local ProcessHitServer = ArgPack.Interfaces.Server.ProcessHit :: Signal.Signal<...any>
			local HitRegisteredSignal =
				ArgPack.Interfaces.Server.HitProcessed :: Signal.Signal<string, Types.CasterEntry>

			local Cleaner = Janitor.new()

			ArgPack.Store.ProcessHitCleaner = Cleaner
			ArgPack.Store.ProcessHitsCompleted = Signal.new() -- Fires when hits are done processing.

			-- If process time is specified, this is how long the server allows the client to process the hit from the time the action was started.

			local entitiesHit = {} :: { Types.Entity }
			local entityPlayer = Players:GetPlayerFromCharacter(ArgPack.Entity)

			ArgPack.Store.ActiveDetectionTypes = {}

			-- How long can the client send hits to the server for this action? Passed argument is how long the client can send hits for from the time the signal is fired.
			ArgPack.Store.StartProcessHitTimer = Signal.new() :: Signal.Signal<()>

			local processHitListener = ProcessHit:Connect(
				withEntityAndState(
					function(
						Player: Player,
						FromEntity: Types.Entity,
						FromState: Types.EntityState,
						Entry: Types.CasterEntry,
						ActionUUID: string
					)
						if HitSameEntity == false and table.find(entitiesHit, Entry.Entity :: Types.Entity) then -- If we don't want to hit the same entity twice, and we've already hit the entity, return.
							-- exception: if we have a hit queue and we're processing hits from the queue, we technically didn't hit the entity yet.
							local isInHitQueue = ArgPack.Store.HitQueue
								and table.find(ArgPack.Store.HitQueue, Entry.Entity)
							if not isInHitQueue then
								return
							end
						end
						if not table.find(ArgPack.Store.ActiveDetectionTypes, Entry.DetectionType) then
							return -- If we're not accepting this detection type, return.
						end
						if ArgPack.Entity ~= (Player.Character :: any) then -- If the entity that sent the hit is not the entity that is performing this action, return.
							return
						end
						if ActionUUID ~= StateInfo.UUID then -- If the action UUID doesn't match, return.
							return
						end
						print("Firing srvr")
						ProcessHitServer:Fire(Player, ActionUUID, ArgPack, StateInfo, FromEntity, FromState, Entry)
					end
				)
			)

			Cleaner:Add(function()
				if processHitListener then
					local index = table.find(processHitListener.NetSignal.connections, processHitListener.RBXSignal)
					if index then
						processHitListener.NetSignal:DisconnectAt(index - 1)
					end
				end
			end)

			Cleaner:Add(
				HitRegisteredSignal:Connect(function(ActionUUID: string, HitEntry: Types.CasterEntry)
					if ActionUUID ~= StateInfo.UUID then
						return -- the hit registered should be related to this action, not other actions that may be getting hit registered.
						-- note: this led to bugs like tiger pursuit not doing damage because the hit registered signal was firing for actions before tiger pursuit,
						-- and since tiger pursuit only hits an entity once, the entity was already hit and inserted to our entitiesHit table for all running actions.
					end

					if HitEntry.Entity then
						table.insert(entitiesHit, HitEntry.Entity)
						if not MultiHit then -- disconnect if we don't want to hit more than once in the same action.
							Cleaner:Destroy()
							Cleaner = nil
						end
					end
				end),
				"Disconnect"
			)

			local stopHitsListener = StopHits:Connect(
				function(Player: Player, ActionUUID: string, DetectionType: Types.Verifier)
					if ActionUUID == StateInfo.UUID and Player == entityPlayer and DetectionTypes[DetectionType] then
						if table.find(ArgPack.Store.ActiveDetectionTypes, DetectionType) then
							table.remove(
								ArgPack.Store.ActiveDetectionTypes,
								table.find(ArgPack.Store.ActiveDetectionTypes, DetectionType)
							)
						end
						if #ArgPack.Store.ActiveDetectionTypes == 0 then
							if Cleaner then
								Cleaner:Destroy() -- destroy will be called after the process time is up.
								Cleaner = nil
							end
						end
					end
				end
			)

			Cleaner:Add(function()
				if stopHitsListener then
					local index = table.find(stopHitsListener.NetSignal.connections, stopHitsListener.RBXSignal)
					if index then
						stopHitsListener.NetSignal:DisconnectAt(index - 1)
					end
				end
			end)

			Cleaner:Add(
				-- @note: in the future, we may want to have the process time passed as an argument to the signal, rather than a global process time for every detection type.
				ArgPack.Store.StartProcessHitTimer:Connect(function(DetectionType: Types.Verifier)
					if ProcessTime then
						task.delay(ProcessTime, function()
							if table.find(ArgPack.Store.ActiveDetectionTypes, DetectionType) then
								table.remove(
									ArgPack.Store.ActiveDetectionTypes,
									table.find(ArgPack.Store.ActiveDetectionTypes, DetectionType)
								)
							end
							-- clean up if this is our last active detection type.
							if #ArgPack.Store.ActiveDetectionTypes == 0 and Cleaner then
								ArgPack.Store.ProcessHitsCompleted:Fire()
								Cleaner:Destroy()
								Cleaner = nil
							end
						end)
					end
				end),
				"Destroy"
			)

			--[[Cleaner:Add(
				ArgPack.Finished:Connect(function()
					-- we need to have some sort of active detection types list before the action finishes, otherwise we'll never clean up.
					if #ArgPack.Store.ActiveDetectionTypes == 0 and Cleaner then
						Cleaner:Destroy()
						Cleaner = nil
					end
				end),
				"Disconnect"
			)--]]

			return true
		end,
	}
end

function GenericProcesses.ListenHitGeneric(_CleanupAfter: number?, MultiHit: boolean?, StoreHitEntries: boolean?)
	return {
		ProcessName = "ListenHit",
		Async = false,
		OnServer = false,
		OnAI = true,
		OnClient = true,
		Delegate = function(ArgPack: Types.ProcessArgs, StateInfo: Types.ActionStateInfo): boolean
			if StoreHitEntries then
				ArgPack.Store.HitEntries = {}
			end

			local function processHit(HitEntry: Types.CasterEntry)
				-- If we have an entity and it's the entity that is performing the action, we don't want to hit it.
				if HitEntry.Entity and (HitEntry.Entity :: any) == ArgPack.Entity then
					return
				elseif HitEntry.Entity and HitEntry.Entity:GetAttribute("ImmuneToHits") == true then
					return
				end
				if ArgPack.Entity:IsDescendantOf(workspace) == false then
					return
				end
				if HitEntry.Entity and StatusModule.HasStatus(HitEntry.Entity, "Killed") then -- If the entity is dead, we don't want to hit it.
					return
				end

				-- If we have an entity and it's on the same team as us, we don't want to hit it.
				local entityTeam = ArgPack.Entity:GetAttribute("Team")
				local hitEntityTeam = HitEntry.Entity and HitEntry.Entity:GetAttribute("Team")
				if entityTeam and hitEntityTeam and entityTeam == hitEntityTeam then
					return -- no friendly fire.
				end

				for _, Tag in NPC_TAGS do
					if CollectionService:HasTag(HitEntry.Entity, Tag) then
						return
					end
				end

				-- If this is the server, we're not going to try and do client-side prediction effects. If this is the client, let's do client-side prediction effects.

				if IS_CLIENT and HitEntry.Entity then
					if HitEntry.Entity and IS_CLIENT then
						-- If we hit an entity, we want to process the hit event.
						ArgPack.Interfaces.Comm.ProcessHit:SendToServer(HitEntry, StateInfo.UUID)
					end
				end

				-- If we're on the server, no client-side prediction effects, this is for AI.
				if HitEntry.Entity and IS_SERVER then
					-- Typically an AI will process hits on the server immediately.
					local ActionService = require(ServerScriptService.services.ActionService)
					ActionService:ProcessHit(
						ArgPack.Entity,
						EntityModule.GetState(ArgPack.Entity) :: Types.EntityState,
						HitEntry.Entity,
						EntityModule.GetState(HitEntry.Entity) :: Types.EntityState,
						HitEntry,
						StateInfo,
						ArgPack
					)
				end

				if ArgPack.Store.HitEntries then
					table.insert(ArgPack.Store.HitEntries, HitEntry)
				end
			end

			if MultiHit then
				ArgPack.Store["OnHit"]:Connect(function(HitEntry: Types.CasterEntry)
					processHit(HitEntry)
				end)
			else
				ArgPack.Store["OnHit"]:ConnectOnce(function(HitEntry: Types.CasterEntry)
					processHit(HitEntry)
				end)
			end

			return true
		end,
	}
end

function GenericProcesses.BuildAudioGeneric(
	PresetName: string | (Types.ProcessArgs, Types.ActionStateInfo) -> Types.Audio?,
	Filter: ((Types.Entity) -> boolean)?
)
	return {
		ProcessName = "BuildAudio",
		Async = false,
		OnServer = true,
		OnAI = true,
		OnClient = false,
		Delegate = function(ArgPack: Types.ProcessArgs, StateInfo: Types.ActionStateInfo): boolean
			-- See if we pass our generic filter.
			if Filter and not Filter(ArgPack.Entity) then
				return true
			end

			local preset = typeof(PresetName) == "function" and PresetName(ArgPack, StateInfo)
			if typeof(PresetName) == "string" then
				preset = PresetName
			end

			local AudioService = ArgPack.Interfaces.Server.AudioService
			if preset then
				AudioService:PlayPreset(preset, ArgPack.Entity.PrimaryPart)
			end
			return true
		end,
	}
end

function GenericProcesses.AttackAnimateGeneric(TrackSpeed: ((Types.ProcessArgs, Types.ActionStateInfo) -> number)?)
	return {
		ProcessName = "Animate",
		Async = false,
		OnServer = false,
		OnClient = true,
		OnAI = true,
		Delegate = function(ArgPack: Types.ProcessArgs, StateInfo: Types.ActionStateInfo): boolean
			local Style = AnimationShared.GetEntityStyle(ArgPack.Entity)
			local AnimContainer = Style[ArgPack.HandlerData.Name]
			local Combo = StateInfo.ActionSpecific.Combo
			local Animation = Combo and AnimContainer[Combo] or AnimContainer
			assert(
				Animation,
				string.format("Could not get animation for [%s] combo [%s]", ArgPack.HandlerData.Name, tostring(Combo))
			)
			local Track = AnimationShared.PlayAnimation(Animation, ArgPack.Entity)

			if TrackSpeed then
				Track:AdjustSpeed(TrackSpeed(ArgPack, StateInfo))
			end

			ArgPack.Store["Track"] = Track
			ArgPack.Janitor:Add(function()
				Track:Stop()
				Track:Destroy()
			end)
			ArgPack.Janitor:Add(
				Track.Stopped:Once(function()
					ArgPack.Finished:Fire(true, ArgPack.HandlerData.Name)
				end),
				"Disconnect"
			)
			ArgPack.Janitor:Add(
				Track.Destroying:Once(function()
					ArgPack.Finished:Fire(false, ArgPack.HandlerData.Name)
				end),
				"Disconnect"
			)

			return true
		end,
	}
end

return GenericProcesses
