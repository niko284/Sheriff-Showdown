--!strict
-- Equipment Handler
-- Nick
-- September 1st, 2023

-- // Variables \\

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = ReplicatedStorage.constants

local Types = require(Constants.Types)

local EquipmentHandler = {}

-- // Functions \\

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
end

return EquipmentHandler
