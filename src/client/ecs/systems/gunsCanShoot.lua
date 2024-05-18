local CollectionService = game:GetService("CollectionService")
local GuiService = game:GetService("GuiService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Packages = ReplicatedStorage.packages

local Components = require(ReplicatedStorage.ecs.components)
local Matter = require(Packages.Matter)
local MatterReplication = require(Packages.MatterReplication)
local Remotes = require(ReplicatedStorage.Remotes)

local CombatNamespace = Remotes.Client:GetNamespace("Combat")
local ProcessAction = CombatNamespace:Get("ProcessAction")

local function gunsCanShoot(world: Matter.World, state)
	local actions = state.actions

	local isShooting = actions:justPressed("shoot")
	local mouseLocation = UserInputService:GetMouseLocation() - GuiService:GetGuiInset()
	local viewportPointRay = workspace.CurrentCamera:ScreenPointToRay(mouseLocation.X, mouseLocation.Y)

	for eid, gun, owner: Components.Owner, serverEntity in
		world:query(Components.Gun, Components.Owner, MatterReplication.ServerEntity)
	do
		if isShooting then
			if gun.CurrentCapacity > -math.huge and owner.OwnedBy == Players.LocalPlayer then
				local hasCooldown = world:get(eid, Components.Cooldown)
				if hasCooldown then
					continue
				end

				local character = (owner.OwnedBy :: Player).Character
				local bulletFilter = { character, unpack(CollectionService:GetTagged("Barrier")) }

				local raycastParams = RaycastParams.new()
				raycastParams.FilterDescendantsInstances = bulletFilter
				raycastParams.FilterType = Enum.RaycastFilterType.Exclude
				local hitPart =
					workspace:Raycast(viewportPointRay.Origin, viewportPointRay.Direction * 1000, raycastParams)

				if hitPart then
					local bulletInstance = Instance.new("Part")
					bulletInstance.CanCollide = false
					bulletInstance.Size = Vector3.new(1, 1, 1)
					bulletInstance.Shape = Enum.PartType.Ball
					bulletInstance.Parent = workspace

					local origin = character:WaitForChild("RightHand").Position
					local dirFromRightHand = (hitPart.Position - character:WaitForChild("RightHand").Position).Unit

					-- make origin cframe at origin position facing the direction of the velocity
					local velocity = dirFromRightHand * gun.BulletSpeed
					local bulletCFrame = CFrame.new(origin, origin + velocity)

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

					world:spawn( -- bullets in our case are not actual projectiles but raycasts.
						Components.Bullet({
							gunId = serverEntity.id,
							filter = bulletFilter,
							currentCFrame = bulletCFrame,
						}),
						Components.Renderable({
							instance = bulletInstance,
						}),
						Components.Transform({
							cframe = bulletCFrame,
						}),
						Components.Velocity({
							velocity = velocity,
						}),
						Components.Lifetime({
							expiry = os.time() + gun.BulletLifeTime,
						})
					)

					ProcessAction:SendToServer({
						action = "Shoot",
						actionId = HttpService:GenerateGUID(false),
						velocity = velocity,
						origin = bulletCFrame,
						fromGun = serverEntity.id,
					})
				end
			end
		end
	end
end

return gunsCanShoot
