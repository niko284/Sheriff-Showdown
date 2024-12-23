--!strict

local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.constants.Types)

local AudioUtils = {}

function AudioUtils.LoadSound(soundId: number): Sound
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://" .. soundId
	sound.Looped = false
	return sound
end

function AudioUtils.PlaySoundOnInstance(soundId: number, instance: Instance): ()
	local sound = AudioUtils.LoadSound(soundId)
	sound.Parent = instance
	sound:Play()
	sound.Ended:Once(function()
		sound:Destroy()
	end)
end

function AudioUtils.IsValidSoundId(soundId: string): boolean
	local soundIdNum = tonumber(soundId)

	if not soundIdNum then
		return false
	end

	local success, productInfo = pcall(function()
		return MarketplaceService:GetProductInfo(soundIdNum) :: Types.ProductInfo
	end)

	if not success then
		return false
	end

	return productInfo.AssetTypeId == 3
end

return AudioUtils
