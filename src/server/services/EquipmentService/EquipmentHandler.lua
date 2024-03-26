--!strict
-- Equipment Handler
-- Nick
-- September 1st, 2023

-- // Variables \\

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SharedAssets = ReplicatedStorage.assets
local Constants = ReplicatedStorage.constants

local GUNS_FOLDER = SharedAssets.guns
local HIDE_FACE_ATTRIBUTE = "HideFace"

local Types = require(Constants.Types)

local EquipmentHandler = {}

-- // Functions \\

function EquipmentHandler.EquipGun(Entity: Types.Entity, ItemData: Types.ItemInfo, EquipType: "Hands" | "Waist")
	local GunSpecificFolder: Instance? = GUNS_FOLDER:WaitForChild(ItemData.Name, 3)
	if not GunSpecificFolder then
		warn(("Gun folder not found: %s"):format(ItemData.Name))
		return
	end

	GunSpecificFolder = GunSpecificFolder:FindFirstChild(EquipType) :: Instance?
	if not GunSpecificFolder then
		warn(("Gun folder equip type not found: %s"):format(EquipType))
		return
	end

	local limbsToHide = GunSpecificFolder:GetAttribute("LimbsToHide")
	local hideFace = GunSpecificFolder:GetAttribute(HIDE_FACE_ATTRIBUTE)

	-- When equipping the item, we also set entity style if applicable.
	if ItemData.Style and EquipType == "Hands" then
		Entity:SetAttribute("Style", ItemData.Style) -- Set style attribute.
	end

	if limbsToHide then
		local limbs = string.split(limbsToHide, ",")

		for _, limbName in limbs do
			-- Remove any spaces
			local limb = Entity:FindFirstChild(select(1, limbName:gsub("%s+", "")) :: any) :: BasePart?
			if limb and limb.Name ~= "HumanoidRootPart" then
				limb.Transparency = 1
			end
		end
	end
	if hideFace == true then
		-- If the entity has a face in their head and we are unequipping a piece that hides the face, show the face.
		local head = Entity:FindFirstChild("Head")
		if head then
			local face = head:FindFirstChild("face") :: Decal?
			if face then
				face.Transparency = 1
			end
		end
	end

	for _, Accessory in GunSpecificFolder:GetChildren() do
		if Accessory:IsA("Accessory") then
			EquipmentHandler.AddAccessory(Entity, Accessory, ItemData)
		elseif Accessory:IsA("Clothing") then
			local oldShirt = Entity:FindFirstChildOfClass("Shirt")
			local oldPants = Entity:FindFirstChildOfClass("Pants")
			if Accessory:IsA("Shirt") and oldShirt then
				oldShirt:Destroy()
			elseif Accessory:IsA("Pants") and oldPants then
				oldPants:Destroy()
			end
			Accessory:Clone().Parent = Entity
		end
	end
end

function EquipmentHandler.UnequipAllGuns(Entity: Types.Entity)
	for _, Descendant in Entity:GetDescendants() do
		if CollectionService:HasTag(Descendant, "Gun") then
			Descendant:Destroy()
		end
	end
end

function EquipmentHandler.AddAccessory(Entity: Types.Entity, accessory: Accessory, ItemData: Types.ItemInfo)
	accessory = accessory:Clone()

	local accessoryAttachment = accessory:FindFirstChildWhichIsA("Attachment", true)
	local handle = accessory:FindFirstChild("Handle")

	if not handle then
		warn(("Handle not found in accessory: %s"):format(accessory.Name))
		return
	end

	if not accessoryAttachment then
		warn(("Attachment not found in accessory: %s"):format(accessory.Name))
		return
	end
	if accessoryAttachment.Name:sub(-13) ~= "RigAttachment" then
		Entity.Humanoid:AddAccessory(accessory)
	else
		-- Rig attachments must be treated differently. Find the specified BodyPart we want to attach to.
		local characterAttachment = Entity:FindFirstChild(accessoryAttachment.Name, true) :: Attachment?
		local weld = Instance.new("Weld")
		if accessory:GetAttribute("AttachmentPart") then -- If a different body part is specified, make sure our attachment comes from that part.
			local bodyPart = Entity:FindFirstChild(accessory:GetAttribute("AttachmentPart"))
			local priorityAttachment = bodyPart and bodyPart:FindFirstChild(accessoryAttachment.Name) :: Attachment?
			if priorityAttachment then
				characterAttachment = priorityAttachment
			end
		end
		if not characterAttachment then
			warn(("Attachment not found in character: %s"):format(accessoryAttachment.Name))
			return
		end

		-- All baseparts should be massless, non-anchored, cancollide off.
		for _, descendant in accessory:GetDescendants() do
			if descendant:IsA("BasePart") then
				descendant.Massless = true
				descendant.Anchored = false
				descendant.CanCollide = false
			end
		end

		accessory.Parent = Entity -- Attach the accessory to the character.
		weld.Name = "AccessoryWeld"
		weld.C0 = characterAttachment.CFrame
		weld.C1 = accessoryAttachment.CFrame
		weld.Part0 = characterAttachment.Parent :: BasePart
		weld.Part1 = accessoryAttachment.Parent :: BasePart
		weld.Parent = handle
		task.spawn(function()
			local accessoryWeld = handle:WaitForChild("AccessoryWeld", 3)
			if accessoryWeld then
				accessoryWeld:Destroy()
			end
		end)
	end
	CollectionService:AddTag(accessory, ItemData.Id)
	CollectionService:AddTag(accessory, ItemData.Type)

	return accessory
end

return EquipmentHandler
