--!strict

-- Effect Utils
-- December 7th, 2022
-- Nick

local Util = {}

local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Packages = ReplicatedStorage.packages
local Assets = ReplicatedStorage:FindFirstChild("assets") :: Folder
local Guns = Assets:FindFirstChild("guns") :: Folder
local Constants = ReplicatedStorage.constants
local Effects = Assets:FindFirstChild("effects") :: Folder
local BulletBeam = Effects:FindFirstChild("Shot") :: Beam

local Janitor = require(Packages.Janitor)
local Promise = require(Packages.Promise)
local Types = require(Constants.Types)

local debris = require(ReplicatedStorage.utils.Debris)

function Util.weldBetween(a: BasePart, b: BasePart): WeldConstraint
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = a
	weld.Part1 = b
	weld.Parent = b

	return weld
end

function Util.CreatePointingBeam(FromPart: BasePart, ToPart: BasePart): (Beam, Attachment, Attachment)
	local Beam = Instance.new("Beam")

	-- Create our beam attachments w/ orientation
	local FromAttachment = Instance.new("Attachment")
	FromAttachment.Orientation = Vector3.new(90, -90, 0)
	FromAttachment.Parent = FromPart

	local ToAttachment = Instance.new("Attachment")
	ToAttachment.Orientation = Vector3.new(90, -90, 0)
	ToAttachment.Parent = ToPart

	Beam.Attachment0 = FromAttachment
	Beam.Attachment1 = ToAttachment
	Beam.Texture = "rbxassetid://14783846631"
	Beam.Brightness = 10
	Beam.Transparency = NumberSequence.new(0)
	Beam.FaceCamera = true
	Beam.TextureSpeed = 5
	Beam.LightInfluence = 0
	Beam.TextureMode = Enum.TextureMode.Static
	Beam.Segments = 1
	Beam.Parent = FromPart

	return Beam, FromAttachment, ToAttachment
end

function Util.ApplyTeamIndicator(Entity: Types.Entity, HighlightColor: Color3)
	local highlight = Instance.new("Highlight")
	highlight.FillTransparency = 0.4
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.OutlineColor = HighlightColor
	highlight.Parent = Entity
	CollectionService:AddTag(highlight, "TeamIndicator")
end

function Util.ToggleWeaponTransparency(Entity: Types.Entity, toggle: boolean)
	local oldParents = {}
	local parentToSet = toggle and Entity or nil
	for _, Descendant in Entity:GetDescendants() do
		if not CollectionService:HasTag(Descendant, "Weapon") then
			continue
		end
		oldParents[Descendant] = Descendant.Parent
		Descendant.Parent = parentToSet
	end
	return function()
		for Descendant, oldParent in pairs(oldParents) do
			Descendant.Parent = oldParent
		end
	end
end

type HitboxProps = {
	SizeTime: number?,
}

function Util.FindPlayingAnimationTrackOfId(AnimationId: string, Entity: Types.Entity): AnimationTrack?
	local otherAnimationId = tonumber(AnimationId:match("%d+"))
	local animator = Entity.Humanoid:FindFirstChildOfClass("Animator")
	if animator then
		for _, track in pairs(animator:GetPlayingAnimationTracks()) do
			local extractedId = tonumber(track.Animation.AnimationId:match("%d+"))
			if extractedId == otherAnimationId then
				return track
			end
		end
	end
	return nil
end

function Util.NPCAttackHitboxNew(CFrame: CFrame, Size: Vector3, Shape: string, Duration: number)
	local hitbox = Util.Part({
		CFrame = CFrame,
		Size = Size,
		Shape = Shape,
		Material = "Plastic",
		Color = Color3.fromRGB(255, 225, 225),
		Anchored = true,
		CanCollide = false,
		Transparency = 0.65,
	})
	hitbox:AddTag("Zone")
	debris.AddSingle(hitbox, Duration + 1.5)

	local colorTween =
		TweenService:Create(hitbox, TweenInfo.new(Duration, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {
			Color = Color3.fromRGB(255, 0, 0),
		})
	colorTween:Play()
	colorTween.Completed:Connect(function()
		hitbox.Material = Enum.Material.Neon
		hitbox.Transparency = 0

		local transparencyTween =
			TweenService:Create(hitbox, TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {
				Transparency = 1,
			})
		transparencyTween:Play()
	end)
end

function Util.NPCAttackHitbox(CFrame: CFrame, Size: Vector3, TimeTillAttack: number, Shape: Enum.PartType?)
	local allComplete = {}
	local hitboxes = {}
	for i = 10, 1, -9 do
		local hitbox = Util.Part({
			CFrame = CFrame,
			Size = Vector3.new(0, 0, 0),
			Shape = Shape,
			Color = Color3.fromRGB(255, 0, 0),
			Anchored = true,
			CanCollide = false,
			Transparency = 0.8,
		})
		table.insert(hitboxes, hitbox)
		local hitboxSizeTween = TweenService:Create(
			hitbox,
			TweenInfo.new(TimeTillAttack / i, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				Size = Size,
			}
		)
		hitboxSizeTween:Play()
		table.insert(
			allComplete,
			Promise.fromEvent(hitboxSizeTween.Completed, function()
				return true
			end)
		)
	end
	Promise.all(allComplete):andThen(function()
		for _, hitbox in hitboxes do
			hitbox:Destroy()
		end
	end)
end

function Util.Part(properties: { [string]: any }, DebrisTime: number?, Tags: { string }?): Part
	local part = Instance.new("Part")
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.CanCollide = false
	part.CanTouch = false

	if Tags then
		for _, tag in pairs(Tags) do
			CollectionService:AddTag(part, tag)
		end
	end

	for i, k in pairs(properties) do -- Filling properties
		if i == "Parent" then
			continue
		end
		if i == "DebrisClear" then
			continue
		end
		(part :: any)[i] = k
	end

	if properties.DebrisClear == nil then
		debris.AddSingle(part, DebrisTime or 10)
	end

	part.Parent = properties.Parent or workspace -- Assign parent last to optimize
	--debris:AddItem(part, 6)

	return part
end

function Util.HandleAbilityTween(
	Target: Instance,
	TweenInfo: TweenInfo,
	Properties: { [string]: any },
	TweenJanitor: Types.Janitor
): Tween
	local tween = TweenService:Create(Target, TweenInfo, Properties)
	if Janitor.Is(TweenJanitor) then
		TweenJanitor:Add(tween, "Destroy")
	end
	tween:Play()
	return tween
end

function Util.SuddenDarkness()
	local colorCorrection = Instance.new("ColorCorrectionEffect")
	colorCorrection.Parent = Lighting
	Debris:AddItem(colorCorrection, 0.25)
	local lightingTween = TweenService:Create(
		colorCorrection,
		TweenInfo.new(0.075, Enum.EasingStyle.Exponential, Enum.EasingDirection.In),
		{
			Brightness = -1,
		}
	)
	lightingTween:Play()
	lightingTween.Completed:Connect(function()
		task.wait(0.1)

		TweenService
			:Create(colorCorrection, TweenInfo.new(0.075, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
				Brightness = 0,
			})
			:Play()
	end)
end

function Util.RockRing(
	cf: CFrame,
	amount: number,
	radius: number,
	size: number,
	isOriented: boolean,
	duration: number,
	RNGObject: Random
)
	local parts = {}

	for i = 1, amount do
		local cframe = cf * CFrame.Angles(0, math.rad(-180 + (360 / amount) * i), 0) * CFrame.new(0, 0, -radius)
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = {}
		local ray = workspace:Raycast(cframe.Position, Vector3.new(0, -15, 0), params)

		if ray then
			local cfDifference = CFrame.new(ray.Position - cframe.Position)
			local finalCF = cframe * cfDifference
			local orientation

			if isOriented then
				orientation = CFrame.Angles(math.rad(-15), 0, 0)
			else
				orientation = CFrame.Angles(
					math.rad(RNGObject:NextNumber(-180, 180)),
					math.rad(RNGObject:NextNumber(-180, 180)),
					math.rad(RNGObject:NextNumber(-180, 180))
				)
			end

			local rayInstance = ray.Instance :: BasePart | Terrain

			local material = rayInstance == workspace.Terrain and ray.Material or rayInstance.Material
			local color = rayInstance == workspace.Terrain and workspace.Terrain:GetMaterialColor(ray.Material)
				or rayInstance.Color

			local rock = Util.Part({
				CFrame = finalCF * orientation,
				Anchored = true,
				CanCollide = false,
				Size = Vector3.new(size, size, size),
				Material = material,
				Color = color,
				CanQuery = false,
			})
			table.insert(parts, rock)
			Debris:AddItem(rock, 3 + duration)
		end
	end

	task.wait(duration)

	for _i, v in parts do
		local transparencyTween =
			TweenService:Create(v, TweenInfo.new(2, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {
				Transparency = 1,
			})
		transparencyTween:Play()
	end
end

function Util.TweenTransparencySequence(object: Beam, fromValue: number, toValue: number, tweenInfo: TweenInfo)
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

function Util.BulletBeam(Entity: Types.Entity, HitPosition: Vector3, EquippedGunName: string?): ()
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
	Util.TweenTransparencySequence(beamClone, 0, 1, transparencyTweenInfo):andThen(function()
		for _, part in parts do
			part:Destroy()
		end
		beamClone:Destroy()
	end)
end

function Util.preFab(ogMesh: BasePart, properties: { [string]: any }, debrisTime: number?): BasePart
	local mesh = ogMesh:Clone() -- Creating mesh

	for i, k in pairs(properties) do -- Filling properties
		if i == "Parent" then
			continue
		end
		if i == "DebrisClear" then
			continue
		end
		if i == "weldPart" then
			continue
		end

		(mesh :: any)[i] = k
	end

	if debrisTime then
		debris.AddSingle(mesh, debrisTime)
	end

	if properties.weldPart then
		Util.weldBetween(mesh, properties.weldPart)
	end

	mesh.Parent = properties.Parent or workspace

	return mesh
end

-- Disable all ParticleEmitters in an instance. Include PointLights in this.

function Util.DisableParticles(Instance: Instance)
	for _, particle in Instance:GetDescendants() do
		if not particle:IsA("ParticleEmitter") then
			continue
		else
			particle.Enabled = false
		end
	end
	for _, light in Instance:GetDescendants() do
		if not light:IsA("PointLight") then
			continue
		else
			TweenService:Create(light, TweenInfo.new(0.08), { Brightness = 0 }):Play()
		end
	end
end

-- Disable all beams
function Util.DisableBeams(Instance: Instance)
	for _, beam in Instance:GetDescendants() do
		if not beam:IsA("Beam") then
			continue
		else
			beam.Transparency = NumberSequence.new(1)
		end
	end
end

-- Enable all beams
function Util.EnableBeams(Instance: Instance)
	for _, beam in Instance:GetDescendants() do
		if not beam:IsA("Beam") then
			continue
		else
			beam.Transparency = NumberSequence.new(0)
		end
	end
end

-- Enable all ParticleEmitters in an instance
function Util.EnableParticles(Instance: Instance, Duration: number?)
	for _, particle in Instance:GetDescendants() do
		if not particle:IsA("ParticleEmitter") then
			continue
		else
			particle.Enabled = true
		end
	end
	if Duration then
		task.delay(Duration, function()
			Util.DisableParticles(Instance)
		end)
	end
end

function Util.EmitAllParticlesByAmount(instance: Instance, Amount: number)
	for _, particle in instance:GetDescendants() do
		if not particle:IsA("ParticleEmitter") then
			continue
		else
			particle:Emit(Amount)
		end
	end
	for _, light in instance:GetDescendants() do
		if not light:IsA("PointLight") then
			continue
		else
			TweenService:Create(light, TweenInfo.new(0.08), { Brightness = light:GetAttribute("Brightness") or 1 })
				:Play()
		end
	end
	return instance
end

-- Emits all children with name with amounts specified in particleInfo
function Util.Emit(thing: Instance, particleInfo: { [string]: number }?): Instance
	for _, particle in thing:GetDescendants() do
		if not particle:IsA("ParticleEmitter") then
			continue
		else
			local emitCount = particleInfo and particleInfo[particle.Name] or particle:GetAttribute("EmitCount")
			if not emitCount then
				continue
			end

			particle:Emit(emitCount)
		end
	end
	for _, light in thing:GetDescendants() do
		if not light:IsA("PointLight") then
			continue
		else
			TweenService:Create(
				light,
				TweenInfo.new(
					light:GetAttribute("TweenTime") or 0.2,
					Enum.EasingStyle.Quad,
					Enum.EasingDirection.InOut,
					0,
					true,
					0
				),
				{ Brightness = light:GetAttribute("Brightness") or 1 }
			):Play()
		end
	end

	return thing
end

function Util.LockCharacter(Entity: Types.Entity)
	local humanoid = Entity.Humanoid
	local rootPart = Entity.HumanoidRootPart
	if humanoid then
		humanoid.AutoRotate = false
	end
	if rootPart then
		rootPart.Anchored = true
		rootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
		rootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
	end
end

function Util.UnlockCharacter(Character: Model)
	if Character:HasTag("Boss") or Character:GetAttribute("RootedInPlace") == true then
		return -- Bosses stand in place
	end

	local humanoid = Character:FindFirstChildOfClass("Humanoid") :: Humanoid
	local rootPart = Character:FindFirstChild("HumanoidRootPart") :: BasePart
	if humanoid then
		humanoid.AutoRotate = true
	end
	if rootPart then
		rootPart.Anchored = false
	end
end

function Util.RaycastDownwards(Entity: Types.Entity)
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = {
		Entity,
		unpack(CollectionService:GetTagged("Zone")),
		unpack(CollectionService:GetTagged("Entity")),
	}
	params.FilterType = Enum.RaycastFilterType.Exclude
	return workspace:Raycast(Entity.HumanoidRootPart.Position, Vector3.new(0, -100, 0), params)
end

function Util.RaycastDownwardsCFrame(CFrame: CFrame)
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = {
		unpack(CollectionService:GetTagged("Zone")),
		unpack(CollectionService:GetTagged("Entity")),
	}
	params.FilterType = Enum.RaycastFilterType.Exclude
	return workspace:Raycast(CFrame.Position, -CFrame.UpVector * 100, params)
end

function Util.VisualizePart(Dir: Vector3, Origin: Vector3, Color: Color3)
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.Color = Color

	-- make part size from origin to dir times 10
	part.Size = Vector3.new(0.1, 0.1, 500)
	part.Material = Enum.Material.Neon

	part.CFrame = CFrame.new(Origin, Origin + Dir)
	part.Parent = workspace
end

return Util
