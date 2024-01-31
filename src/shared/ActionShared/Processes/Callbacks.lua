--!strict
-- Callbacks
-- July 25th, 2023
-- Nick

-- // Variables \\

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = ReplicatedStorage.constants
local Serde = ReplicatedStorage.serde

local Types = require(Constants.Types)
local UUIDSerde = require(Serde.UUIDSerde)

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

return Callbacks
