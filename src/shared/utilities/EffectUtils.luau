--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Promise = require("@packages/Promise")

local Assets = ReplicatedStorage:FindFirstChild("assets") :: Folder
local Guns = Assets:FindFirstChild("guns") :: Folder
local Other = Assets:FindFirstChild("other") :: Folder
local BulletBeam = Other:FindFirstChild("Shot") :: Beam

local EffectUtils = {}

function EffectUtils.TweenTransparencySequence(object: Beam, fromValue: number, toValue: number, tweenInfo: TweenInfo)
	local numberValue = Instance.new("NumberValue")
	numberValue.Value = fromValue

	numberValue.Changed:Connect(function(value)
		object.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, value),
			NumberSequenceKeypoint.new(1, value),
		})
	end)

	local tween = TweenService:Create(numberValue, tweenInfo, { Value = toValue })
	tween.Completed:Once(function()
		numberValue:Destroy()
	end)

	tween:Play()

	return Promise.fromEvent(tween.Completed, function()
		return true
	end)
end

function EffectUtils.SetDescendantsProperty(instance: Instance, className: string, propertyName: string, value: any): ()
	for _, descendant in instance:GetDescendants() do
		if descendant:IsA(className) then
			pcall(function()
				(descendant :: any)[propertyName] = value
			end)
		end
	end
end

function EffectUtils.EmitParticleCount(instance: Instance, count: number)
	for _, descendant in instance:GetDescendants() do
		if descendant:IsA("ParticleEmitter") then
			descendant:Emit(count)
		end
	end
end

function EffectUtils.DisableBeams(instance: Instance)
	for _, beam in instance:GetDescendants() do
		if beam:IsA("Beam") then
			beam.Transparency = NumberSequence.new(1)
		end
	end
end

function EffectUtils.EnableBeams(instance: Instance)
	for _, beam in instance:GetDescendants() do
		if beam:IsA("Beam") then
			beam.Transparency = NumberSequence.new(0)
		end
	end
end

function EffectUtils.BulletBeam(Entity: Instance, HitPosition: Vector3, EquippedGunName: string?): ()
	local rightHand = Entity:FindFirstChild("RightHand") :: BasePart
	if not rightHand then
		return
	end

	local beamClone = nil

	-- see if the gun has a custom beam in its gun folder
	if EquippedGunName then
		local gunFolder = Guns:FindFirstChild(EquippedGunName)
		if gunFolder then
			local shotBeam = gunFolder:FindFirstChild("ShotBeam") :: Beam?
			if shotBeam then
				beamClone = shotBeam:Clone()
			end
		end
	end
	if not beamClone then
		beamClone = BulletBeam:Clone()
	end

	assert(beamClone, "No beam found")

	local startPart = Instance.new("Part")
	local endPart = Instance.new("Part")

	local parts = { startPart, endPart }
	parts[1].CFrame = rightHand.CFrame
	parts[2].CFrame = CFrame.new(HitPosition)

	for _, part in parts do
		part.Size = Vector3.new(0.1, 0.1, 0.1)
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.Transparency = 1
		part.Parent = workspace
	end

	local initialAttachment = Instance.new("Attachment")
	initialAttachment.Parent = parts[1]

	local endAttachment = Instance.new("Attachment")
	endAttachment.Parent = parts[2]

	beamClone.Parent = rightHand
	beamClone.Attachment0 = endAttachment
	beamClone.Attachment1 = initialAttachment

	local transparencyTweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
	EffectUtils.TweenTransparencySequence(beamClone, 0, 1, transparencyTweenInfo):andThen(function()
		for _, part in parts do
			part:Destroy()
		end
		beamClone:Destroy()
	end)
end

return EffectUtils
