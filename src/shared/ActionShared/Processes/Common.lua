--!strict

-- Combat Controller
-- November 17th, 2022
-- Ron

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Processes = script.Parent
local ActionShared = ReplicatedStorage.ActionShared
local Serde = ReplicatedStorage.serde
local Constants = ReplicatedStorage.constants
local Packages = ReplicatedStorage.packages
local Utils = ReplicatedStorage.utils

local Action = require(ActionShared.Action)
local AnimationShared = require(Utils.AnimationShared)
local DetectionTypes = require(Constants.DetectionTypes)
local EntityModule = require(ActionShared.Entity)
local FastCast = require(Packages.FastCast)
local HitFXSerde = require(Serde.HitFXSerde)
local Janitor = require(Packages.Janitor)
local PhysicsUtils = require(Utils.PhysicsUtils)
local ProjectileShared = require(Utils.ProjectileShared)
local Promise = require(Packages.Promise)
local Sift = require(Packages.Sift)
local StatusModule = require(ActionShared.StatusModule)
local Types = require(Constants.Types)
local UUIDSerde = require(Serde.UUIDSerde)

local IS_SERVER = RunService:IsServer()
local IS_CLIENT = RunService:IsClient()
local MAXIMUM_LATENCY = 0.8 -- 800 ms
local MAX_LENIENCY_PROJECTILE_ORIGIN = 15
local INTERPOLATION_VALUE = 0.048

FastCast.VisualizeCasts = true

local Common = {
	Generic = require(Processes.Generic),
	Callbacks = require(Processes.Callbacks),
	ActionPriorities = {
		Low = 0,
		Medium = 1,
		High = 2,
	} :: { [string]: number },
}

Common.ChangeState = {
	ProcessName = "ChangeState",
	Async = false,
	OnServer = true,
	OnClient = true,
	OnAI = true,
	Delegate = function(ArgPack: Types.ProcessArgs, StateInfo: Types.ActionStateInfo): boolean
		-- This is typically the last process in the VerifyStack after we have verified the action. We can now consider this our previous action. What's left is finishing the action through ActionStack.

		local newState = table.clone(EntityModule.GetState(ArgPack.Entity) :: Types.EntityState)

		if newState then
			-- Update attack and defense levels.
			newState.DefenseLevel = ArgPack.HandlerData.DefenseLevel or 0
			newState.AttackLevel = ArgPack.HandlerData.AttackLevel or 0
			newState.LastActionState = StateInfo
			newState.ActionHistory[StateInfo.ActionHandlerName] = StateInfo
			EntityModule.ChangeState(ArgPack.Entity, newState)
		end

		-- When we update our last action state, also update the history of last action states.

		Action.LastActionStates[ArgPack.Entity].LastActionState = {
			ActionState = StateInfo,
			ArgPack = ArgPack,
		}
		Action.LastActionStates[ArgPack.Entity][StateInfo.ActionHandlerName :: any] =
			Action.LastActionStates[ArgPack.Entity].LastActionState

		local player = Players:GetPlayerFromCharacter(ArgPack.Entity)
		if player then
			-- weird bug where :GetPlayerFromCharacter() sometimes won't return the player to make the last action states table for the player.
			-- leads to the "no attack" bug
			Action.LastActionStates[player] = Action.LastActionStates[ArgPack.Entity]
		end

		return true
	end,
} :: Types.Process

Common.Verify = {
	ProcessName = "Verify",
	Async = false,
	OnServer = true,
	OnClient = true,
	OnAI = true,
	Delegate = function(ArgPack: Types.ProcessArgs, StateInfo: Types.ActionStateInfo): boolean
		-- Verification of our action.
		local NowMillis = StateInfo.TimestampMillis
		local EntityState = EntityModule.GetState(ArgPack.Entity) :: Types.EntityState
		local PreviousSame = EntityState.ActionHistory[StateInfo.ActionHandlerName]

		local overlappableActions = ArgPack.HandlerData.OverlappableActions

		local function VerifyActionState(ActionState: Types.ActionStateInfo?)
			local doesOverlap = table.find(
				overlappableActions or {},
				ActionState and ActionState.ActionHandlerName or ""
			) ~= nil
			-- if our action can overlap, we don't care about the last action state.
			if ActionState and doesOverlap == false then
				if ActionState.Finished == false then
					-- check if our action is cancellable.
					if
						ArgPack.HandlerData.Cancellable == true
						and ActionState.ActionHandlerName == StateInfo.ActionHandlerName
					then
						StateInfo.CancelPreviousAction = true
						Action.FinishAction(ArgPack.Entity, nil, StateInfo.ActionHandlerName :: any) -- this fires the Finished signal which fires FinishedClient on the server too, cancelling the action.
						return true, "Cancelled"
					end
					-- if our priority is less or equal to the last action's priority, or we're the same action, then we cannot interrupt the last action.
					local priorityValues = Common.ActionPriorities
					local lastActionPriority = priorityValues[ActionState.Priority]
					local thisActionPriority = priorityValues[StateInfo.Priority]
					if thisActionPriority <= lastActionPriority then
						return false, "Cannot interrupt last action"
					end
				end

				if PreviousSame then
					-- Return false if our action's cooldown isn't finished yet.
					local leniency = 0
					if IS_SERVER then
						leniency = ArgPack.HandlerData.CooldownMillis / 10 -- 10% leniency on cooldowns.
					end
					if NowMillis < (PreviousSame.CooldownFinishTimeMillis - leniency) then
						return false, "Action cooldown not finished"
					end

					if ActionState ~= PreviousSame then
						-- If our action is not the most previous action, then we must also respect global cooldown.
						if NowMillis < ActionState.GlobalCooldownFinishTimeMillis then
							return false, "Global cooldown not finished"
						end
					end

					StateInfo.ActionSpecific = PreviousSame.ActionSpecific
				elseif NowMillis < ActionState.GlobalCooldownFinishTimeMillis then
					-- Otherwise, return false if the action is not past the global action cooldown.
					return false, "Global cooldown not finished"
				end
			end

			-- Now that we've past the cooldown and priority checks, we can interrupt the last action if it's not finished, and we're not overlapping with it.
			-- we don't check if the action state is finished because the server wants to finish this action too. (race condition between FinishedClient + Common.Verify)
			if ActionState and doesOverlap == false then
				if ActionState.Sustaining then
					ActionState.Sustaining = false
				end
				-- Fire the finished signal of the action immediately because we're running a new action right now. We can't wait a frame for the action to finish
				-- or else the finished signal will fire after the new action has started which can lead to undesired behavior.
				Action.FinishAction(ArgPack.Entity, nil, ActionState.ActionHandlerName :: any)
			end

			return true, "Verified"
		end

		-- Return false if entity is already busy. (This is only set externally to lock character actions outside of combat.) This also checks for sustained actions and statuses.
		if EntityModule.IsBusy(ArgPack.Entity) then
			return false, "Entity is busy"
		end

		local verified, reason = VerifyActionState(EntityState.LastActionState)
		if verified == false then
			return verified, reason
		end

		-- verify all action states since we may want to interrupt overlapping actions that were previously running.
		for _, actionState in pairs(EntityState.ActionHistory) do
			-- Now that we've passed the cooldown and priority checks, we can interrupt the last action if it's not finished, and we're not overlapping with it.
			local doesOverlap = table.find(
				overlappableActions or {},
				actionState and actionState.ActionHandlerName or ""
			) ~= nil
			if actionState and doesOverlap == false then
				if actionState.Sustaining then
					actionState.Sustaining = false
				end
				-- Fire the finished signal of the action immediately because we're running a new action right now. We can't wait a frame for the action to finish
				-- or else the finished signal will fire after the new action has started which can lead to undesired behavior.
				Action.FinishAction(ArgPack.Entity, nil, actionState.ActionHandlerName :: any)
			end
		end

		if ArgPack.Callbacks.VerifyActionPayload and IS_SERVER then
			-- If there is an initial server load, we want to verify if the data sent is on par with what the server expects.
			if not ArgPack.ActionPayload then
				return false, "No action payload"
			end
			local isValid = ArgPack.Callbacks.VerifyActionPayload(ArgPack.ActionPayload)
			if isValid == false then
				return false, "Invalid action payload"
			end
		end

		return verified, reason
	end,
} :: Types.Process

function Common.VerifyEntitiesInRange(
	Range: number,
	FilterState: ((Types.EntityState, Types.Entity, Types.ProcessArgs) -> boolean)?
)
	return {
		ProcessName = "EntityInActionRange",
		Async = false,
		OnServer = true,
		OnAI = true,
		OnClient = true,
		Delegate = function(ArgPack: Types.ProcessArgs, _StateInfo: Types.ActionStateInfo): boolean
			local Entity = ArgPack.Entity

			local EntitiesInRange = Sift.Array.filter(
				EntityModule.GetEntitiesInRange(Entity, Range, { ArgPack.Entity }),
				function(InRangeEntity)
					local EntityState = EntityModule.GetState(InRangeEntity) :: Types.EntityState
					if FilterState then
						return FilterState(EntityState, InRangeEntity, ArgPack)
					end
					return true
				end
			)

			ArgPack.Store.EntitiesInRange = EntitiesInRange -- Store entities in range for potential use in the action.

			-- Also store the closest entity in range.
			local closestEntity = nil
			local closestDistance = math.huge
			for _, entityInRange in EntitiesInRange do
				local distance = (entityInRange:GetPivot().Position - Entity:GetPivot().Position).Magnitude
				if distance < closestDistance then
					closestDistance = distance
					closestEntity = entityInRange
				end
			end

			ArgPack.Store.ClosestEntityInRange = closestEntity

			return #EntitiesInRange > 0 -- If there are no entities in range, this action will not verify, such as for grip.
		end,
	}
end

function Common.BuildComboVerify(
	MaxCombo: number,
	ResetTimeMillis: number,
	ComboCooldownMillis: number,
	EndComboCooldownMillis: number
): Types.Process
	return {
		ProcessName = "VerifyCombo",
		Async = false,
		OnServer = true,
		OnAI = true,
		OnClient = true,
		Delegate = function(ArgPack: Types.ProcessArgs, StateInfo: Types.ActionStateInfo): boolean
			local NowMillis = StateInfo.TimestampMillis

			local EntityState = EntityModule.GetState(ArgPack.Entity) :: Types.EntityState
			local PreviousSame = EntityState.ActionHistory[StateInfo.ActionHandlerName]

			if PreviousSame then
				if
					(NowMillis - PreviousSame.TimestampMillis) > ResetTimeMillis
					or PreviousSame.ActionSpecific.Combo == MaxCombo
				then
					-- We reset the combo back to one if our previous action was too long ago (greater than ResetTimeMillis), or if we reached the last combo. No local cooldown here.
					StateInfo.CooldownFinishTimeMillis = NowMillis
					StateInfo.ActionSpecific.Combo = 1
				elseif PreviousSame.ActionSpecific.Combo then
					-- Otherwise, we increment the combo.
					local NewCombo = PreviousSame.ActionSpecific.Combo + 1
					StateInfo.ActionSpecific.Combo = NewCombo

					-- We are now at the last combo, so our action cooldown starts from this point.
					if NewCombo == MaxCombo then
						StateInfo.CooldownFinishTimeMillis = NowMillis + ComboCooldownMillis
						StateInfo.GlobalCooldownFinishTimeMillis = NowMillis + EndComboCooldownMillis
					else
						-- If we are not at the last combo, we don't have a local cooldown.
						if Players:GetPlayerFromCharacter(ArgPack.Entity) then
							StateInfo.CooldownFinishTimeMillis = NowMillis
						end
					end
				end
			else
				-- If we have no previous same action, then we start the combo at one with no local cooldown.
				StateInfo.CooldownFinishTimeMillis = NowMillis
				StateInfo.ActionSpecific.Combo = 1
				StateInfo.ActionSpecific.MaxCombo = MaxCombo
			end

			return true
		end,
	}
end

function Common.BuildWalkSpeed(Walkspeed: number | (Types.ProcessArgs) -> number): Types.Process
	return {
		ProcessName = "Walkspeed",
		Async = false,
		OnServer = true,
		OnAI = true,
		OnClient = false,
		Delegate = function(ArgPack: Types.ProcessArgs, _StateInfo: Types.ActionStateInfo): boolean
			local speed = typeof(Walkspeed) == "function" and Walkspeed(ArgPack) or Walkspeed
			--local success, cleaner = StatusModule.ApplyStatus(ArgPack.Entity, "Speed", nil, nil, speed)

			ArgPack.Finished:Once(function()
				--[[local entityState = EntityModule.GetState(ArgPack.Entity) :: Types.EntityState
				-- @TODO: Remove this check when statuses are stateless, aka don't rely on previous walkspeeds.
				if entityState and #entityState.Statuses > 0 then -- If we're in a status, we don't want to go back to our old walkspeed since our status effect will change our walkspeed.
					-- Status effects will cancel our action so this would also fire causing conflicting walkspeeds.
					return
				end--]]

				--if success and cleaner and Janitor.Is(cleaner) then
				--	cleaner:Cleanup()
				--end
			end)

			return true
		end,
	}
end

function Common.BuildAutoRotate(AutoRotate: boolean): Types.Process
	return {
		ProcessName = "BuildAutoRotate",
		Async = false,
		OnServer = true,
		OnClient = false,
		OnAI = true,
		Delegate = function(ArgPack: Types.ProcessArgs, _StateInfo: Types.ActionStateInfo): boolean
			ArgPack.Entity.Humanoid.AutoRotate = AutoRotate

			ArgPack.Finished:Once(function()
				ArgPack.Entity.Humanoid.AutoRotate = not AutoRotate
			end)

			return true
		end,
	}
end

function Common.LockCharacter(RootPartAnchored: boolean, AutoRotate: boolean): Types.Process
	return {
		ProcessName = "LockCharacter",
		Async = false,
		OnServer = false, -- let's do it on client for instant feedback.
		OnClient = true,
		OnAI = true,
		Delegate = function(ArgPack: Types.ProcessArgs, _StateInfo: Types.ActionStateInfo): boolean
			local Entity = ArgPack.Entity
			local humanoid = Entity.Humanoid
			local rootPart = Entity.HumanoidRootPart

			rootPart.Anchored = RootPartAnchored

			humanoid.AutoRotate = AutoRotate

			ArgPack.Finished:Once(function()
				if rootPart then
					rootPart.Anchored = false
				end
				humanoid.AutoRotate = true
			end)

			return true
		end,
	}
end

function Common.BuildAbility(CallbackName: string): Types.Process
	return {
		ProcessName = "DoAbility",
		Async = false,
		OnServer = false,
		OnClient = true,
		OnAI = true,
		Delegate = function(ArgPack: Types.ProcessArgs, StateInfo: Types.ActionStateInfo): boolean
			local FXFunc = ArgPack.Callbacks[CallbackName] :: (
				Types.VFXArguments,
				(() -> ())?
			) -> (boolean, ((boolean?) -> ())?, RBXScriptSignal?, Types.Janitor?) -- ability effect functions have specific arguments and return a cleanup function.

			if FXFunc then
				local VFXArgs: Types.VFXArguments = {
					State = StateInfo,
					TargetEntity = ArgPack.Entity,
					ArgPack = ArgPack, -- This is for our local client only, not other clients who display the same effect on their end.
				}

				local wasFinished = false
				-- noError means that there were no errors in executing the ability function, callbackSuccess means that the ability function returned a success value.
				local noError, callbackSuccess, ToClean, finishedEvent, effectJanitor = pcall(FXFunc, VFXArgs)
				if ToClean then
					ArgPack.Janitor:Add(function()
						local entityState = EntityModule.GetState(ArgPack.Entity) :: Types.EntityState
						if wasFinished or (entityState and #entityState.Statuses > 0) then -- if we were interrupted by a status but not by some sort of failure, we don't want to clean up our effects.
							ToClean(false) -- our ability finished properly, so let our effects also finish properly.
						else
							ToClean(true) -- our ability was interrupted by a process stack failure probably.
						end
					end)
				end
				if effectJanitor then
					-- Store the effect janitor so we can add to it later if we need to.
					ArgPack.Store.AbilityJanitor = effectJanitor
				end

				if finishedEvent then
					finishedEvent:Once(function()
						wasFinished = true
						ArgPack.Finished:Fire(true, ArgPack.HandlerData.Name)
					end)
				else
					wasFinished = true
					ArgPack.Finished:Fire(true, ArgPack.HandlerData.Name)
				end

				if callbackSuccess == true and noError then
					return true
				elseif noError == false then
					-- callbackSuccess is an error message.
					warn(string.format("Ability callback [%s] failed", callbackSuccess :: any))
					return false
				else
					warn(string.format("Ability callback did not return success for [%s]", CallbackName))
					return false
				end
			end

			warn(string.format("Could not find ability FX callback [%s]", CallbackName))
			-- Ability was not found.

			return false
		end,
	}
end

function Common.ReplicateEffect(
	effectName: string,
	buildVFXArgs: (Types.ProcessArgs, Types.ActionStateInfo) -> Types.VFXArguments,
	shouldReplicateAI: boolean?
): Types.Process
	return {
		ProcessName = "ReplicateEffect",
		Async = false,
		OnServer = true,
		OnClient = false,
		OnAI = shouldReplicateAI or false,
		Delegate = function(ArgPack: Types.ProcessArgs, StateInfo: Types.ActionStateInfo): boolean
			local serverComm = ArgPack.Interfaces.Comm
			local processEffectReplicator = serverComm.ProcessFX
			local plr = Players:GetPlayerFromCharacter(ArgPack.Entity)

			if plr then
				-- If the entity doing the action is a player, we don't want to replicate the effect to them twice.
				processEffectReplicator:SendToAllPlayersExcept(
					plr,
					ArgPack.HandlerData.Name,
					effectName,
					HitFXSerde.Serialize(buildVFXArgs(ArgPack, StateInfo))
				)
			else
				processEffectReplicator:SendToAllPlayers(
					ArgPack.HandlerData.Name,
					effectName,
					HitFXSerde.Serialize(buildVFXArgs(ArgPack, StateInfo))
				)
			end
			return true
		end,
	}
end

type ProjectileData = {
	Projectile: BasePart?,
	Origin: CFrame,
	Velocity: number,
	Lifetime: number,
	Direction: Vector3,
	MarkerName: string?,
}
type ProjectileInternal = {
	GetProjectile: (Types.Entity, Types.ProcessArgs) -> ProjectileData?,
	CasterShape: "Sphere" | "Block" | "Conform"?,
	MarkerName: string?,
	OnShoot: ((Projectile: BasePart, ArgPack: Types.ProcessArgs, StateInfo: Types.ActionStateInfo) -> BasePart)?,
	OnImpact: ((Entry: Types.CasterEntry) -> ())?,
}
type ProjectileServerInternal = {
	RayHit: RaycastResult?,
	Origin: CFrame,
	Velocity: number,
	Lifetime: number,
	Direction: Vector3,
}
function Common.ProjectileCast(Projectiles: { ProjectileInternal })
	return {
		ProcessName = "ProjectileCast",
		Async = false,
		OnServer = true,
		OnClient = true,
		OnAI = true,
		Delegate = function(ArgPack: Types.ProcessArgs, StateInfo: Types.ActionStateInfo): boolean
			local Cleaner = ArgPack.Janitor

			local entityPlayer = Players:GetPlayerFromCharacter(ArgPack.Entity)

			if IS_CLIENT then
				local processServerEffect = ArgPack.Interfaces.Comm.ProcessServerEffect

				local StopHits = ArgPack.Interfaces.Comm.StopHits

				local function castProjectile(Projectile: ProjectileInternal)
					local index = table.find(Projectiles, Projectile)

					local projectileData = Projectile.GetProjectile(ArgPack.Entity, ArgPack)
					if not projectileData then
						return
					end
					local projectile = projectileData.Projectile
					if Projectile.OnShoot and projectile then
						Projectile.OnShoot(projectile, ArgPack, StateInfo)
					end
					local initialPromise = nil
					if Projectile.CasterShape == "Block" and projectile then
						initialPromise = ProjectileShared.BlockcastProjectile(projectile, { ArgPack.Entity })
					elseif Projectile.CasterShape == "Sphere" and projectile then
						local radius = math.min(projectile.Size.Z, projectile.Size.Y) / 2
						initialPromise = ProjectileShared.SpherecastProjectile(projectile, radius, { ArgPack.Entity })
					elseif Projectile.CasterShape == "Conform" and projectile then
						initialPromise = ProjectileShared.ShapecastProjectile(projectile, { ArgPack.Entity })
					else
						local caster = FastCast.new()
						local behavior = FastCast.newBehavior()
						local newParams = RaycastParams.new()
						newParams.FilterDescendantsInstances = { ArgPack.Entity }
						newParams.FilterType = Enum.RaycastFilterType.Exclude
						behavior.RaycastParams = newParams
						local activeCast = caster:Fire(
							projectileData.Origin.Position,
							projectileData.Direction.Unit,
							projectileData.Velocity * projectileData.Direction.Unit,
							behavior
						)
						initialPromise = Promise.fromEvent(caster.RayHit, function(cast, result)
							return cast == activeCast and result and true
						end):andThen(function(_cast, result)
							return result
						end)
					end
					initialPromise
						:andThen(function(raycastResult: RaycastResult)
							local casterEntry: Types.CasterEntry = {
								HitPart = raycastResult.Instance :: PVInstance,
								Entity = EntityModule.GetNestedEntity(raycastResult.Instance),
								RaycastResult = raycastResult,
								DetectionType = DetectionTypes.Projectile,
								HitPosition = raycastResult.Position,
							}
							if Projectile.OnImpact then
								Projectile.OnImpact(casterEntry)
							end
							if projectile then
								projectile:Destroy() -- We should maybe abstract this out to a callback somehow!
							end
							ArgPack.Store["OnHit"]:Fire(casterEntry)
						end)
						:catch(function() end)
						:finally(function()
							if index == #Projectiles then -- if this was our last projectile, we can stop listening for hits.
								StopHits:SendToServer(UUIDSerde.Serialize(StateInfo.UUID), "Projectile")
							end
						end)
					return projectileData.Origin
				end

				local wasRegistered = false
				for _, Projectile in Projectiles do
					local initPromise = Promise.resolve()
					if Projectile.MarkerName then
						initPromise = Promise.fromEvent(
							ArgPack.Store["Track"]:GetMarkerReachedSignal(Projectile.MarkerName),
							function()
								return true
							end
						)
					end
					Cleaner:AddPromise(initPromise:andThen(function()
						local origin = castProjectile(Projectile)
						if not wasRegistered then -- we only create projectiles once on the server
							wasRegistered = true
							processServerEffect:SendToServer("CreateProjectile", workspace:GetServerTimeNow(), origin)
						end
					end))
				end
			elseif IS_SERVER and entityPlayer then
				local processServerEffect = ArgPack.Interfaces.Comm.ProcessServerEffect
				local listener = nil
				local processHitCleaner = ArgPack.Store.ProcessHitCleaner

				listener = processServerEffect:Connect(
					function(Player: Player, EffectName: string, Timestamp: number, ProjectileOrigin: CFrame)
						if
							EffectName == "CreateProjectile"
							and (Player.Character :: any == ArgPack.Entity)
							and typeof(ProjectileOrigin) == "CFrame"
						then
							local Time = os.clock()
							local Latency = (workspace:GetServerTimeNow() - Timestamp)
							local Interpolation = (Player:GetNetworkPing() + INTERPOLATION_VALUE)

							--> Validate the latency and avoid players with very slow connections
							if (Latency < 0) or (Latency > MAXIMUM_LATENCY) then
								return
							end

							local projectileData = {} :: { ProjectileServerInternal }

							for _, Projectile in Projectiles do
								-- Create our verifier function for hit detection.
								local serverProjectileData = Projectile.GetProjectile(ArgPack.Entity, ArgPack)

								if not serverProjectileData then
									continue
								end

								-- check the player origin against the projectile origin to make sure the player isn't cheating.
								local distance = (ProjectileOrigin.Position - serverProjectileData.Origin.Position).Magnitude

								if serverProjectileData.Projectile then
									serverProjectileData.Projectile:Destroy()
								end
								if distance > MAX_LENIENCY_PROJECTILE_ORIGIN then
									continue
								end

								local velocity = serverProjectileData.Velocity
								local lifetime = serverProjectileData.Lifetime
								local direction = serverProjectileData.Direction

								local projectileServer = {
									RayHit = nil,
									Origin = ProjectileOrigin,
									Velocity = if typeof(velocity) == "Vector3" then velocity.Magnitude else velocity,
									Direction = direction,
									Lifetime = lifetime,
								} :: ProjectileServerInternal
								table.insert(projectileData, projectileServer)
							end

							table.insert(ArgPack.Store.ActiveDetectionTypes, DetectionTypes.Projectile) -- note that we're accepting projectile hits.

							-- Start the process timer for projectile listeners.
							ArgPack.Store.StartProcessHitTimer:Fire(DetectionTypes.Projectile)

							ArgPack.HitVerifiers.ProjectileCheckGeneric = function(Entry: Types.CasterEntry)
								if not Entry.HitPosition or not Entry.Entity then
									return false
								elseif not Entry.Entity.PrimaryPart then
									return false
								end

								local atLeastOneHit = false

								-- Check that at least one of our projectiles hit the entity.
								for _, ProjectileData in projectileData do
									-- we want to check if the entry hit is in a reasonable field of view / angle and distance from the projectile if the server didn't hit anything.

									-- we want the displacement vector with origin at our projectile origin and end at the hit entity's position.
									local displacementVector = (
										Entry.Entity:GetPivot().Position - ProjectileData.Origin.Position
									).Unit
									-- we also want the vector of the hit direction with origin at our projectile origin.
									local hitDirection = ProjectileData.Direction.Unit

									-- get angle in degrees between the two vectors.
									local angle = math.deg(math.acos(displacementVector:Dot(hitDirection)))

									if angle > 40 then
										continue
									end

									-- we also want to check if the hit is within a reasonable distance from the projectile.
									-- we need to predict the position of the projectile at the time of the hit.

									local projectedPosition = PhysicsUtils.GetPositionAtTime(
										ProjectileData.Origin.Position,
										ProjectileData.Direction * ProjectileData.Velocity,
										Vector3.zero, -- no gravity
										os.clock() - (Time - Latency - Interpolation)
									)

									-- make sure nothing is in the way of the projectile and the hit.
									local raycastParams = RaycastParams.new()
									raycastParams.FilterType = Enum.RaycastFilterType.Exclude
									raycastParams.FilterDescendantsInstances = { ArgPack.Entity }
									raycastParams.IgnoreWater = true

									local raycastResult = workspace:Raycast(
										ProjectileData.Origin.Position,
										ProjectileData.Direction.Unit
											* ProjectileData.Velocity
											* ProjectileData.Lifetime,
										raycastParams
									)

									if raycastResult then
										if raycastResult.Instance:IsDescendantOf(Entry.Entity) == false then
											--continue
										end
									end

									local distance = (Entry.HitPosition - projectedPosition).Magnitude

									if distance > 20 then -- 20 studs is a lenient distance.
										--continue
									end

									atLeastOneHit = true
									break
								end

								return atLeastOneHit
							end

							local index = table.find(listener.NetSignal.connections, listener.RBXSignal)
							if index then
								listener.NetSignal:DisconnectAt(index - 1)
							end
						end
					end
				) :: any

				processHitCleaner:Add(function()
					local index = table.find(listener.NetSignal.connections, listener.RBXSignal)
					if index then
						listener.NetSignal:DisconnectAt(index - 1)
					end
				end)
			end

			return true
		end,
	}
end

function Common.AnimatePassive(PassiveName: string)
	return {
		ProcessName = "AnimatePassive",
		Async = false,
		OnServer = false,
		OnAI = true,
		OnClient = true,
		Delegate = function(ArgPack: Types.ProcessArgs, _StateInfo: Types.ActionStateInfo): boolean
			local Style = AnimationShared.GetEntityStyle(ArgPack.Entity)

			assert(
				Style.PassiveAnimations,
				string.format("Could not get passive animations for [%s]", ArgPack.Entity.Name)
			)

			local Animation = Style.PassiveAnimations[PassiveName]

			assert(Animation, string.format("Could not get passive animation for [%s]", PassiveName))
			local Track = AnimationShared.PlayAnimation(Animation, ArgPack.Entity)

			ArgPack.Store["Track"] = Track
			ArgPack.Janitor:Add(function()
				Track:Stop()
				Track:Destroy()
			end)

			return true
		end,
	}
end

function Common.BuildActionPayload(constructLoad: (
	ArgPack: Types.ProcessArgs,
	StateInfo: Types.ActionStateInfo
) -> { [string]: any })
	return {
		ProcessName = "BuildActionPayload",
		Async = false,
		OnServer = false,
		OnAI = true,
		OnClient = true,
		Delegate = function(ArgPack: Types.ProcessArgs, StateInfo: Types.ActionStateInfo): boolean
			local load = constructLoad(ArgPack, StateInfo)
			ArgPack.ActionPayload = load
			return true
		end,
	}
end

Common.ServerWaitForFinished = {
	ProcessName = "ServerWaitForFinished",
	Async = false,
	OnServer = true,
	OnClient = false,
	OnAI = true,
	Delegate = function(ArgPack: Types.ProcessArgs, StateInfo: Types.ActionStateInfo): boolean
		local waitTime = (ArgPack.HandlerData.CooldownMillis / 1000) / 2

		-- While the action is not finished, and the entity is still in the workspace, wait. (If the entity is removed like if it dies or if a player entity leaves the game, we want to stop waiting.)
		-- Then our finished event fires and we can clean up appropriately.
		while not StateInfo.Finished and ArgPack.Entity:IsDescendantOf(workspace) do
			task.wait(waitTime)
		end

		ArgPack.Finished:Fire(true, ArgPack.HandlerData.Name)

		return true
	end,
}

Common.ClientWaitForFinished = {
	ProcessName = "ClientWaitForFinished",
	Async = false,
	OnServer = false,
	OnClient = true,
	OnAI = false,
	Delegate = function(ArgPack: Types.ProcessArgs, StateInfo: Types.ActionStateInfo): boolean
		local waitTime = (ArgPack.HandlerData.CooldownMillis / 1000) / 2

		-- While the action is not finished, and the entity is still in the workspace, wait. (If the entity is removed like if it dies or if a player entity leaves the game, we want to stop waiting.)
		-- Then our finished event fires and we can clean up appropriately.
		while not StateInfo.Finished and ArgPack.Entity:IsDescendantOf(workspace) do
			task.wait(waitTime)
		end
		ArgPack.Finished:Fire(true, ArgPack.HandlerData.Name)

		return true
	end,
}
Common.CallServer = {
	ProcessName = "CallServer",
	Async = true,
	OnServer = false,
	OnClient = true,
	Delegate = function(ArgPack: Types.ProcessArgs, StateInfo: Types.ActionStateInfo): boolean
		local didFinish = ArgPack.Interfaces.Comm.ProcessAction:CallServerAsync(StateInfo.ActionHandlerName):expect()

		if not didFinish then
			return false
		end

		return true
	end,
}

return Common
