--!strict

local CollectionService = game:GetService("CollectionService")
local GuiService = game:GetService("GuiService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local jecs = require("@packages/jecs")

local BlinkClient = require("@client/modules/BlinkClient")
local Components = require("@ecs/components")
local Input = require("@packages/Input")
local KeybindInputController = require("@controllers/KeybindInputController")
local UUIDSerde = require("@utilities/UUIDSerde")

local PreferredInput = Input.PreferredInput

local Assets = ReplicatedStorage:FindFirstChild("assets") :: Folder
local Animations = Assets:FindFirstChild("animations") :: Folder

local SHOOT_ANIMATION = Animations:FindFirstChild("gunshoot") :: Animation
local DOUBLE_TAP_THRESHOLD_S = 0.4

-- Per-animator shoot track cache.
local shootTracks: { [Animator]: AnimationTrack } = {}

type State = {
	actions: any,
	inputState: any,
	inputMap: any,
	replecsClient: any,
	lastTapped: number?,
	lastTapPosition: Vector2?,
	releaseTouch: (() -> ())?,
}

-- Connect touch signals once.
local touchConnected = false

local function gunsCanShoot(world: jecs.World, state: State)
	local replecsClient = state.replecsClient

	if not touchConnected then
		touchConnected = true
		UserInputService.TouchStarted:Connect(function(inputObject: InputObject, gameProcessed: boolean)
			if gameProcessed then
				return
			end
			local nowSec = DateTime.now().UnixTimestampMillis / 1000
			local wasDoubleTapped = state.lastTapped and (nowSec - state.lastTapped <= DOUBLE_TAP_THRESHOLD_S)
			state.lastTapped = nowSec
			if wasDoubleTapped then
				state.lastTapPosition = Vector2.new(inputObject.Position.X, inputObject.Position.Y)
				state.releaseTouch = state.actions:hold("shoot")
			end
		end)
		UserInputService.TouchEnded:Connect(function()
			if state.releaseTouch then
				state.releaseTouch()
				state.releaseTouch = nil
			end
		end)
	end

	local isShooting = state.actions:pressed("shoot")
	if not isShooting then
		return
	end

	for eid, gun, owner in world:query(Components.Gun, Components.Owner):without(Components.Cooldown) do
		if owner.OwnedBy ~= Players.LocalPlayer or gun.Disabled == true then
			continue
		end

		local serverGunId = replecsClient and replecsClient:get_server_entity(eid)
		if not serverGunId then
			continue
		end

		local mouseLocation = UserInputService:GetMouseLocation() - GuiService:GetGuiInset()
		if PreferredInput.Current == "Touch" and KeybindInputController:IsMobileShiftLockEnabled() then
			mouseLocation = Vector2.new(0.5, 0.5)
		elseif PreferredInput.Current == "Touch" then
			mouseLocation = state.lastTapPosition or mouseLocation
		end

		local viewportPointRay = workspace.CurrentCamera:ScreenPointToRay(mouseLocation.X, mouseLocation.Y)

		local character = (owner.OwnedBy :: any).Character :: Model
		local bulletFilter = { character, table.unpack(CollectionService:GetTagged("Barrier")) }

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local animator = humanoid and humanoid:FindFirstChildOfClass("Animator") :: Animator?
		if animator then
			local shootTrack = shootTracks[animator]
			if not shootTrack then
				shootTrack = animator:LoadAnimation(SHOOT_ANIMATION)
				shootTracks[animator] = shootTrack
			end
			if not shootTrack.IsPlaying then
				shootTrack:Play()
			end
		end

		local raycastParams = RaycastParams.new()
		raycastParams.FilterDescendantsInstances = bulletFilter
		raycastParams.FilterType = Enum.RaycastFilterType.Exclude
		local hit = workspace:Raycast(viewportPointRay.Origin, viewportPointRay.Direction * 1000, raycastParams)

		if not hit then
			continue
		end

		local rightHand = character:WaitForChild("RightHand") :: BasePart
		local dirFromRightHand = (hit.Position - rightHand.Position).Unit
		local velocity = dirFromRightHand * gun.BulletSpeed
		local bulletCFrame = CFrame.lookAt(rightHand.Position, rightHand.Position + dirFromRightHand)

		local newCapacity = gun.CurrentCapacity - 1
		local timeNow = DateTime.now()
		local cooldownMillis = newCapacity == 0 and gun.ReloadTimeMillis or gun.LocalCooldownMillis

		world:set(eid, Components.Cooldown, { expiry = timeNow.UnixTimestampMillis + cooldownMillis })
		world:set(eid, Components.Gun, {
			LocalCooldownMillis = gun.LocalCooldownMillis,
			ReloadTimeMillis = gun.ReloadTimeMillis,
			Damage = gun.Damage,
			CriticalDamage = gun.CriticalDamage,
			BulletLifeTime = gun.BulletLifeTime,
			MaxCapacity = gun.MaxCapacity,
			ReloadTime = gun.ReloadTime,
			CurrentCapacity = newCapacity == 0 and gun.MaxCapacity or newCapacity,
			BulletSpeed = gun.BulletSpeed,
			BulletSoundId = gun.BulletSoundId,
			KnockStrength = gun.KnockStrength,
			Disabled = gun.Disabled,
			Reloading = cooldownMillis == gun.ReloadTimeMillis or nil,
		})

		local actionUUID = HttpService:GenerateGUID(false)
		local bulletId = world:entity()
		world:set(bulletId, Components.Projectile, { gunId = serverGunId, filter = bulletFilter, origin = bulletCFrame })
		world:set(bulletId, Components.Transform, { cframe = bulletCFrame })
		world:set(bulletId, Components.Velocity, { velocity = velocity })
		world:set(bulletId, Components.Lifetime, { expiry = (DateTime.now().UnixTimestampMillis / 1000) + gun.BulletLifeTime })
		world:set(bulletId, Components.Owner, { OwnedBy = owner.OwnedBy })
		world:set(bulletId, Components.Identifier, { uuid = actionUUID })

		BlinkClient.ProcessAction.Fire({
			action = "Shoot",
			actionId = UUIDSerde.Serialize(actionUUID),
			velocity = velocity,
			origin = bulletCFrame,
			fromGun = serverGunId,
			timestamp = workspace:GetServerTimeNow(),
		})
	end
end

return gunsCanShoot
