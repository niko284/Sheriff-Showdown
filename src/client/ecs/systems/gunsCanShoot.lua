local CollectionService = game:GetService("CollectionService")
local GuiService = game:GetService("GuiService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local UserInputService = game:GetService("UserInputService")

local Packages = ReplicatedStorage.packages
local Utils = ReplicatedStorage.utils

local Components = require(ReplicatedStorage.ecs.components)
local Input = require(ReplicatedStorage.packages.Input)
local KeybindInputController = require(StarterPlayer.StarterPlayerScripts.controllers.KeybindInputController)
local Matter = require(Packages.Matter)
local MatterReplication = require(Packages.MatterReplication)
local MatterTypes = require(ReplicatedStorage.ecs.MatterTypes)
local Remotes = require(ReplicatedStorage.network.Remotes)
local Types = require(ReplicatedStorage.constants.Types)
local UUIDSerde = require(Utils.UUIDSerde)
local useAnimation = require(ReplicatedStorage.ecs.hooks.useAnimation)

local PreferredInput = Input.PreferredInput

local CombatNamespace = Remotes.Client:GetNamespace("Combat")
local ProcessAction = CombatNamespace:Get("ProcessAction")

local Assets = ReplicatedStorage:FindFirstChild("assets") :: Folder
local Animations = Assets:FindFirstChild("animations") :: Folder

local SHOOT_ANIMATION = Animations:FindFirstChild("gunshoot") :: Animation
local DOUBLE_TAP_THRESHOLD_S = 0.4

local useEvent = Matter.useEvent

local function gunsCanShoot(world: Matter.World, state)
	local actions = state.actions

	local isShooting = actions:pressed("shoot")

	for eid, gun: MatterTypes.ComponentInstance<Components.Gun>, owner: Components.Owner, serverEntity in
		world:query(Components.Gun, Components.Owner, MatterReplication.ServerEntity):without(Components.Cooldown)
	do
		if isShooting then
			if owner.OwnedBy == Players.LocalPlayer and gun.Disabled ~= true then
				local mouseLocation = UserInputService:GetMouseLocation() - GuiService:GetGuiInset()

				if PreferredInput.Current == "Touch" and KeybindInputController:IsMobileShiftLockEnabled() == true then
					mouseLocation = Vector2.new(0.5, 0.5)
				elseif PreferredInput.Current == "Touch" then
					mouseLocation = state.lastTapPosition or mouseLocation
				end

				local viewportPointRay = workspace.CurrentCamera:ScreenPointToRay(mouseLocation.X, mouseLocation.Y)

				local character = (owner.OwnedBy :: any).Character :: Types.Character
				local bulletFilter = { character, unpack(CollectionService:GetTagged("Barrier")) }

				local animator = character.Humanoid:FindFirstChildOfClass("Animator")

				useAnimation(animator, SHOOT_ANIMATION, false)

				local raycastParams = RaycastParams.new()
				raycastParams.FilterDescendantsInstances = bulletFilter
				raycastParams.FilterType = Enum.RaycastFilterType.Exclude
				local hitPart =
					workspace:Raycast(viewportPointRay.Origin, viewportPointRay.Direction * 1000, raycastParams)

				if hitPart then
					local origin = character:WaitForChild("RightHand").Position
					local dirFromRightHand = (hitPart.Position - character:WaitForChild("RightHand").Position).Unit

					-- make origin cframe at origin position facing the direction of the velocity
					local velocity = dirFromRightHand * gun.BulletSpeed
					local bulletCFrame = CFrame.lookAt(origin, origin + dirFromRightHand)

					local newCapacity = gun.CurrentCapacity - 1

					local timeNow = DateTime.now()
					local cooldownMillis = newCapacity == 0 and gun.ReloadTimeMillis or gun.LocalCooldownMillis

					world:insert(
						eid,
						Components.Cooldown({
							expiry = timeNow.UnixTimestampMillis + cooldownMillis,
						})
					)

					gun = gun:patch({
						CurrentCapacity = newCapacity == 0 and gun.MaxCapacity or newCapacity,
						Reloading = cooldownMillis == gun.ReloadTimeMillis,
					})
					world:insert(eid, gun)

					local actionUUID = HttpService:GenerateGUID(false)
					world:spawn(
						Components.Bullet({
							gunId = serverEntity.id,
							filter = bulletFilter,
							origin = bulletCFrame,
						}),
						Components.Transform({
							cframe = bulletCFrame,
						}),
						Components.Velocity({
							velocity = velocity,
						}),
						Components.Lifetime({
							expiry = (DateTime.now().UnixTimestampMillis / 1000) + gun.BulletLifeTime,
						}),
						Components.Owner({
							OwnedBy = owner.OwnedBy,
						}),
						Components.Identifier({
							uuid = actionUUID,
						})
					)

					ProcessAction:SendToServer({
						action = "Shoot",
						actionId = UUIDSerde.Serialize(actionUUID),
						velocity = velocity,
						origin = bulletCFrame,
						fromGun = serverEntity.id,
						timestamp = workspace:GetServerTimeNow(),
					})
				end
			end
		end
	end

	-- detect gun shooting for mobile

	for _, inputObject: InputObject, gameProcessed in useEvent(UserInputService, "TouchStarted") do
		if gameProcessed then
			continue
		end
		local nowMillis = DateTime.now().UnixTimestampMillis
		local wasDoubleTapped = state.lastTapped and (nowMillis / 1000 - state.lastTapped <= DOUBLE_TAP_THRESHOLD_S)
		state.lastTapped = nowMillis / 1000
		if wasDoubleTapped then
			state.lastTapPosition = Vector2.new(inputObject.Position.X, inputObject.Position.Y)
			state.releaseTouch = state.actions:hold("shoot")
		end
	end

	for _ in useEvent(UserInputService, "TouchEnded") do
		if state.releaseTouch then
			state.releaseTouch()
			state.releaseTouch = nil
		end
	end
end

return gunsCanShoot
