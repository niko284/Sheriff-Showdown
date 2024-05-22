--!strict

-- Shoot
-- January 27th, 2024
-- Ron

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Constants = ReplicatedStorage.constants
local ActionShared = ReplicatedStorage.ActionShared
local Processes = ActionShared.Processes
local Utils = ReplicatedStorage.utils
local Packages = ReplicatedStorage.packages
local Serde = ReplicatedStorage.serde

local Callbacks = require(Processes.Callbacks)
local Common = require(Processes.Common)
local EffectUtils = require(Utils.EffectUtils)
local FastCast = require(Packages.FastCast)
local HitFXSerde = require(Serde.HitFXSerde)
local InstanceUtils = require(Utils.InstanceUtils)
local ItemUtils = require(Utils.ItemUtils)
local RoundUtils = require(Utils.RoundUtils)
local TableUtils = require(Utils.TableUtils)
local Types = require(Constants.Types)
local t = require(Packages.t)

-- << HANDLER DATA

-- Action constants
-- MS = Milliseconds

-- Base handler data for action recognition and interaction.
local HandlerData: Types.ActionHandlerData = {
	Name = "Shoot",
	GlobalCooldownMillis = 1000,
	CooldownMillis = 1000,
	IsBaseAction = true,
	AttackLevel = 1,
	DefenseLevel = 0,
	Sustained = false,
	BaseDamage = function(Entry: Types.CasterEntry)
		if Entry.Entity and Entry.HitPart then
			-- headshots get all of the target's health, otherwise just 1/3 of their max health
			local maxHealth = Entry.Entity.Humanoid.MaxHealth
			if Entry.HitPart.Name == "Head" then
				return maxHealth
			else
				-- on three hits we get a rounding issue where the target is left with 1 health, so we need to round up
				return math.ceil(maxHealth / 3)
			end
		end
		return 0
	end,
	SettingsData = {
		Name = "Shoot",
		InputData = {
			MouseKeyboard = Enum.UserInputType.MouseButton1,
			Gamepad = Enum.KeyCode.ButtonR2,
			Touch = Enum.UserInputType.Touch,
		},
		Held = {},
		DoubleTap = {},
	},
	Priority = "Medium",
}

local Handler: Types.ActionHandler = {
	Data = HandlerData,
	Callbacks = {
		VerifyActionPayload = function(ActionPayload: { Direction: Vector3, Origin: Vector3 }): boolean
			return t.strictInterface({
				Direction = t.Vector3,
				Origin = t.Vector3,
			})(ActionPayload)
		end,
		ProcessHit = function()
			return true, {}
		end,
		VerifyHits = Common.Callbacks.VerifyHits({
			Projectile = { "ProjectileCheckGeneric" },
		}),
		OnHit = function(_VFXArgs: Types.VFXArguments) end,
		HitNoise = function()
			return "LightHit"
		end,
		BulletBeam = function(
			HitFX: { Target: Types.Entity, Origin: Vector3, Direction: Vector3 },
			EquippedGunName: string?
		)
			local filterDescendants = { HitFX.Target, unpack(InstanceUtils.GetAllPlayerAccessories() :: { any }) }

			local caster = FastCast.new()
			local behavior = FastCast.newBehavior()
			local newParams = RaycastParams.new()
			newParams.FilterDescendantsInstances = filterDescendants
			newParams.FilterType = Enum.RaycastFilterType.Exclude
			behavior.RaycastParams = newParams
			local activeCast = caster:Fire(HitFX.Origin, HitFX.Direction, 5000 * HitFX.Direction, behavior)

			caster.RayHit:Once(function(cast, result)
				if cast == activeCast then
					EffectUtils.BulletBeam(HitFX.Target, result.Position, EquippedGunName)
				end
			end)
		end,
		ExplosionDistraction = Callbacks.ExplosionDistraction(),
	},
	ProcessStack = {
		VerifyStack = {
			{
				ProcessName = "GetWorldPosition",
				Async = false,
				OnClient = true,
				OnServer = false,
				OnAI = false,
				Delegate = function(ArgPack: Types.ProcessArgs, _StateInfo: Types.ActionStateInfo)
					local currentCamera = workspace.CurrentCamera
					local inputObject = ArgPack.InputObject

					local mouseLocation = UserInputService:GetMouseLocation()

					if inputObject then
						local unitRay = currentCamera:ViewportPointToRay(mouseLocation.X, mouseLocation.Y)

						local origin = ArgPack.Entity.HumanoidRootPart.Position

						local raycastParams = RaycastParams.new()
						raycastParams.FilterType = Enum.RaycastFilterType.Exclude
						raycastParams.FilterDescendantsInstances =
							{ ArgPack.Entity, unpack(CollectionService:GetTagged("Barrier")) }

						local rayLanding = workspace:Raycast(unitRay.Origin, unitRay.Direction * 9999, raycastParams)
						if rayLanding then
							local shootDirection = (rayLanding.Position - origin).Unit
							ArgPack.Store.Direction = shootDirection
							ArgPack.Store.Origin = origin

							return true
						else
							return false
						end
					end

					return false
				end,
			},
			Common.BuildActionPayload(function(ArgPack: Types.ProcessArgs, _StateInternal: Types.ActionStateInfo)
				local ActionPayload = {
					Direction = ArgPack.Store.Direction,
					Origin = ArgPack.Store.Origin,
				}
				return ActionPayload
			end),
			Common.Verify,
			{
				ProcessName = "RoundVerification",
				Async = false,
				OnServer = true,
				OnClient = false,
				Delegate = function(ArgPack: Types.ProcessArgs, StateInfo: Types.ActionStateInfo)
					local playerEntity = Players:GetPlayerFromCharacter(ArgPack.Entity)
					if not playerEntity then
						return true
					end

					local currentRound = RoundUtils.GetCurrentRound()
					if currentRound then
						local roundModeExtension = RoundUtils.GetRoundModeExtension(currentRound.RoundMode)
						if roundModeExtension and roundModeExtension.VerifyActionRequest then
							return roundModeExtension.VerifyActionRequest(playerEntity, StateInfo)
						end
					end

					return true
				end,
			},
			Common.ChangeState,
		},
		ActionStack = {
			Common.Generic.ProcessHitGeneric(1, true, false),
			Common.Generic.AttackAnimateGeneric(),
			Common.Generic.BuildAudioGeneric(function(ArgPack: Types.ProcessArgs, _StateInfo: Types.ActionStateInfo)
				local player = Players:GetPlayerFromCharacter(ArgPack.Entity)

				if player then
					local inventoryService = ArgPack.Interfaces.Server.InventoryService
					local itemsOfType = inventoryService:GetItemsOfType(player, "Gun", true)
					local equippedGun = itemsOfType[1]

					if equippedGun then
						local equippedGunInfo = ItemUtils.GetItemInfoFromId(equippedGun.Id)
						if equippedGunInfo and equippedGunInfo.ShootAudio then
							return {
								AudioId = string.format("rbxassetid://%d", equippedGunInfo.ShootAudio),
								Looped = false,
								Volume = 1,
								SoundGroupName = "Effects",
							}
						end
					end
				end
				return nil
			end) :: Types.Process,
			Common.Generic.ListenHitGeneric(nil, true) :: Types.Process,
			{
				ProcessName = "ServerEffects",
				Async = false,
				OnClient = false,
				OnServer = true,
				OnAI = false,
				Delegate = function(ArgPack: Types.ProcessArgs)
					-- this will clean up the hit listener when hit processing for this action is done (1 second max, or when the client tells us to stop listening)

					ArgPack.Store.ProcessHitCleaner:Add(
						ArgPack.Store.OnHit:Connect(function(Entry: Types.CasterEntry)
							-- if we hit a player, slow them down by 15% every time we hit them
							if Entry.Entity then
								local humanoid = Entry.Entity:FindFirstChildOfClass("Humanoid")
								if humanoid then
									humanoid.WalkSpeed = humanoid.WalkSpeed * 0.85
								end
							end
						end),
						"Disconnect"
					)

					local playerEntity = Players:GetPlayerFromCharacter(ArgPack.Entity)

					local inventoryService = ArgPack.Interfaces.Server.InventoryService

					local serverComm = ArgPack.Interfaces.Comm
					local processEffectReplicator = serverComm.ProcessFX

					local hitFXArgs = {
						Target = ArgPack.Entity,
						Direction = ArgPack.ActionPayload and ArgPack.ActionPayload.Direction or Vector3.zero, -- the server doesn't have access to the mouse location, so we need to pass the direction from the client
						-- then the client can use the direction to calculate the hit position w/ the origin.
						Origin = ArgPack.ActionPayload and ArgPack.ActionPayload.Origin or Vector3.zero,
					} :: Types.VFXArguments

					local playerGun = inventoryService:GetItemsOfType(playerEntity, "Gun", true)[1] :: Types.Item
					local playerGunInfo = ItemUtils.GetItemInfoFromId(playerGun and playerGun.Id or 2) -- use the default gun if we can't find the player's gun

					if playerEntity then
						processEffectReplicator:SendToAllPlayersExcept(
							playerEntity,
							ArgPack.HandlerData.Name,
							"BulletBeam",
							HitFXSerde.Serialize(hitFXArgs),
							playerGunInfo.Name -- gun item name
						)
					else
						processEffectReplicator:SendToAllPlayers(
							ArgPack.HandlerData.Name,
							"BulletBeam",
							HitFXSerde.Serialize(hitFXArgs),
							playerGunInfo.Name
						)
					end
					return true
				end,
			},
			Common.ProjectileCast({
				{
					MarkerName = "shoot",
					GetProjectile = function(_Entity: Types.Entity, ArgPack: Types.ProcessArgs)
						local actionPayload = ArgPack.ActionPayload :: any
						local projectileDirection = actionPayload.Direction
						local projectileOrigin = actionPayload.Origin

						return {
							Origin = projectileOrigin,
							Direction = projectileDirection,
							Velocity = 5000,
							Lifetime = 1,
						}
					end,
					OnImpact = function(ArgPack: Types.ProcessArgs, CasterEntry: Types.CasterEntry) -- this fn is only called on the client side.
						if CasterEntry.HitPosition then
							local inventoryController = ArgPack.Interfaces.Client.InventoryController
							local playerGun = inventoryController:GetItemsOfType("Gun", true)[1]
							local playerGunInfo = ItemUtils.GetItemInfoFromId(playerGun and playerGun.Id or 2) -- use the default gun if we can't find the player's gun
							EffectUtils.BulletBeam(ArgPack.Entity, CasterEntry.HitPosition, playerGunInfo.Name)
						end
					end,
				},
			}),
			Common.ServerWaitForFinished :: Types.Process,
		},
	},
}

TableUtils.RecursiveFreeze(Handler)

return Handler
