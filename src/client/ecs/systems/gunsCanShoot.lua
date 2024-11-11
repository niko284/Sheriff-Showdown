local CollectionService = game:GetService("CollectionService")
local GuiService = game:GetService("GuiService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Packages = ReplicatedStorage.packages
local Utils = ReplicatedStorage.utils

local Components = require(ReplicatedStorage.ecs.components)
local Matter = require(Packages.Matter)
local MatterReplication = require(Packages.MatterReplication)
local Remotes = require(ReplicatedStorage.network.Remotes)
local UUIDSerde = require(Utils.UUIDSerde)

local CombatNamespace = Remotes.Client:GetNamespace("Combat")
local ProcessAction = CombatNamespace:Get("ProcessAction")

local function gunsCanShoot(world: Matter.World, state)
	local actions = state.actions

	local isShooting = actions:justPressed("shoot")
	local mouseLocation = UserInputService:GetMouseLocation() - GuiService:GetGuiInset()
	local viewportPointRay = workspace.CurrentCamera:ScreenPointToRay(mouseLocation.X, mouseLocation.Y)

	for eid, gun, owner: Components.Owner, serverEntity in
		world:query(Components.Gun, Components.Owner, MatterReplication.ServerEntity):without(Components.Cooldown)
	do
		if isShooting then
			if gun.CurrentCapacity > -math.huge and owner.OwnedBy == Players.LocalPlayer and gun.Disabled ~= true then
				local character = (owner.OwnedBy :: Player).Character
				local bulletFilter = { character, unpack(CollectionService:GetTagged("Barrier")) }

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

					gun = gun:patch({
						CurrentCapacity = gun.CurrentCapacity - 1,
					})
					world:insert(eid, gun)

					local timeNow = DateTime.now()
					world:insert(
						eid,
						Components.Cooldown({
							expiry = timeNow.UnixTimestampMillis + gun.LocalCooldownMillis,
						})
					)

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
							expiry = os.time() + gun.BulletLifeTime,
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
end

return gunsCanShoot
