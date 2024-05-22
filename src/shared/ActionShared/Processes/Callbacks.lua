--!strict
-- Callbacks
-- July 25th, 2023
-- Nick

-- // Variables \\

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = ReplicatedStorage.constants
local Serde = ReplicatedStorage.serde
local Utils = ReplicatedStorage.utils
local Assets = ReplicatedStorage:FindFirstChild("assets") :: Folder
local EffectsFolder = Assets:FindFirstChild("effects") :: Folder

local EffectUtils = require(Utils.EffectUtils)
local Types = require(Constants.Types)
local UUIDSerde = require(Serde.UUIDSerde)

local EXPLOSION_DISTRACTION = EffectsFolder:FindFirstChild("ExplosionDistraction") :: BasePart

-- // Callbacks \\

local Callbacks = {}

function Callbacks.RegisterServerEffect(
	Effect: string,
	EffectCallback: (...any) -> any,
	ArgPack: Types.ProcessArgs,
	StateInfo: Types.ActionStateInfo
): (() -> ())?
	local processServerEffect = ArgPack.Interfaces.Comm.ProcessServerEffect

	local listener = nil
	listener = processServerEffect:Connect(function(Player: Player, EffectName: string, ActionUUID: string, ...: any)
		if Effect == EffectName and Player.Character == (ArgPack.Entity :: any) then
			local deserializedUUID = UUIDSerde.Deserialize(ActionUUID)
			if StateInfo.UUID == deserializedUUID then
				EffectCallback(...)
			end
		end
	end) :: any

	return function()
		local index = table.find(listener.NetSignal.connections, listener.RBXSignal)
		if index then
			listener.NetSignal:DisconnectAt(index - 1)
		end
	end
end

function Callbacks.VerifyHits(VerifierNames: { [Types.Verifier]: { string } })
	return function(ArgPack: Types.ProcessArgs, VerifyTaskName: Types.Verifier, HitEntry: Types.CasterEntry): boolean
		local Verifiers = ArgPack.HitVerifiers
		if not Verifiers then
			return true
		end
		for _, verifierName in VerifierNames[VerifyTaskName] do
			local verifier = Verifiers[verifierName]
			if verifier then
				if not verifier(HitEntry) then
					return false
				end
			else
				return false -- If we don't have the verifier, then we can't verify the hit.
			end
		end
		return true
	end
end

function Callbacks.ExplosionDistraction()
	return function(VFXArgs: Types.VFXArguments)
		if VFXArgs.TargetEntity then
			local explosionDistractionEffect =
				EffectUtils.preFab(EXPLOSION_DISTRACTION, { CFrame = VFXArgs.TargetEntity.HumanoidRootPart.CFrame })
			EffectUtils.weldBetween(VFXArgs.TargetEntity.HumanoidRootPart, explosionDistractionEffect)

			local audioController = require(Players.LocalPlayer.PlayerScripts.controllers.AudioController)

			audioController:PlayPreset("DistractionExplosion", VFXArgs.TargetEntity.PrimaryPart)

			EffectUtils.EmitAllParticlesByAmount(explosionDistractionEffect, 100)
		end
	end
end

return Callbacks
