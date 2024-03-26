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

local Common = require(Processes.Common)
local ItemUtils = require(Utils.ItemUtils)
local TableUtils = require(Utils.TableUtils)
local Types = require(Constants.Types)
local t = require(Packages.t)

-- << HANDLER DATA

-- Action constants
-- MS = Milliseconds

-- Base handler data for action recognition and interaction.
local HandlerData: Types.ActionHandlerData = {
	Name = "Shoot",
	GlobalCooldownMillis = 3000,
	CooldownMillis = 3000,
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

						local raycastParams = RaycastParams.new()
						raycastParams.FilterType = Enum.RaycastFilterType.Exclude
						raycastParams.FilterDescendantsInstances =
							{ ArgPack.Entity, CollectionService:GetTagged("Barrier") }

						local rayLanding = workspace:Raycast(unitRay.Origin, unitRay.Direction * 9999, raycastParams)
						if rayLanding then
							local shootDirection = (rayLanding.Position - ArgPack.Entity.HumanoidRootPart.Position).Unit
							ArgPack.Store.Direction = shootDirection

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
				}
				return ActionPayload
			end),
			Common.Verify,
			Common.ChangeState,
		},
		ActionStack = {
			Common.Generic.ProcessHitGeneric(1, true, false),
			Common.Generic.AttackAnimateGeneric(),
			Common.Generic.BuildAudioGeneric(function(ArgPack: Types.ProcessArgs, StateInfo: Types.ActionStateInfo)
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
				ProcessName = "SlowDown",
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
					return true
				end,
			},
			Common.ProjectileCast({
				{
					MarkerName = "shoot",
					GetProjectile = function(Entity: Types.Entity, ArgPack: Types.ProcessArgs)
						local actionPayload = ArgPack.ActionPayload :: any
						local projectileDirection = actionPayload.Direction

						local RightHand = Entity:FindFirstChild("RightHand") :: BasePart

						return {
							Origin = RightHand.CFrame,
							Direction = projectileDirection,
							Velocity = 5000,
							Lifetime = 1,
						}
					end,
				},
			}),
			Common.ServerWaitForFinished :: Types.Process,
		},
	},
}

TableUtils.RecursiveFreeze(Handler)

return Handler
