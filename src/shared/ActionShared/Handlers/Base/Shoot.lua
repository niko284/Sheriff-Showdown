--!strict

-- Shoot
-- January 27th, 2024
-- Ron

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = ReplicatedStorage.constants
local ActionShared = ReplicatedStorage.ActionShared
local Processes = ActionShared.Processes
local Utils = ReplicatedStorage.utils
local Packages = ReplicatedStorage.packages

local Common = require(Processes.Common)
local TableUtils = require(Utils.TableUtils)
local Types = require(Constants.Types)
local t = require(Packages.t)

-- << HANDLER DATA

-- Action constants
-- MS = Milliseconds

-- Base handler data for action recognition and interaction.
local HandlerData: Types.ActionHandlerData = {
	Name = "Shoot",
	GlobalCooldownMillis = 300,
	CooldownMillis = 100,
	IsBaseAction = true,
	AttackLevel = 1,
	DefenseLevel = 0,
	Sustained = false,
	BaseDamage = 100,
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

					if inputObject then
						local unitRay = currentCamera:ScreenPointToRay(inputObject.Position.X, inputObject.Position.Y)

						ArgPack.Store.Direction = unitRay.Direction
						ArgPack.Store.Origin = unitRay.Origin

						return true
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
			Common.ChangeState,
		},
		ActionStack = {
			Common.Generic.ProcessHitGeneric(1, true, false),
			Common.Generic.AttackAnimateGeneric(),
			Common.Generic.ListenHitGeneric(nil, true) :: Types.Process,
			Common.ProjectileCast({
				{
					MarkerName = "shoot",
					GetProjectile = function(_Entity: Types.Entity, ArgPack: Types.ProcessArgs)
						local actionPayload = ArgPack.ActionPayload :: any
						local projectileDirection = actionPayload.Direction
						local origin = actionPayload.Origin
						return {
							Origin = CFrame.new(origin),
							Direction = projectileDirection,
							Velocity = 5000,
							Lifetime = 5,
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
