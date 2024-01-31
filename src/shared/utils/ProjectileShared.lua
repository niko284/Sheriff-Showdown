-- Projectile Shared
-- February 11th, 2023

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Packages = ReplicatedStorage.packages

local Promise = require(Packages.Promise)

local ProjectileShared = {}

function ProjectileShared.RaycastFromAttachments(
	Projectile: BasePart,
	AttachmentName: string,
	Params: RaycastParams
): { RaycastResult }
	local RaycastResults = {}
	for _, Attachment in Projectile:GetDescendants() do
		if Attachment:IsA("Attachment") and Attachment.Name == AttachmentName then
			local RaycastResult = workspace:Raycast(Attachment.WorldPosition, Projectile.CFrame.LookVector * 2, Params)
			if RaycastResult then
				table.insert(RaycastResults, RaycastResult)
			end
		end
	end
	return RaycastResults
end

function ProjectileShared.ListenForRayCollision(Projectile: BasePart, IgnoreList: { Instance })
	local Params = RaycastParams.new()
	table.insert(IgnoreList, Projectile)
	Params.FilterDescendantsInstances = IgnoreList
	Params.FilterType = Enum.RaycastFilterType.Exclude
	return Promise.new(function(resolve, reject)
		local initialResults = ProjectileShared.RaycastFromAttachments(Projectile, "ProjectileRay", Params)
		if initialResults[1] then
			resolve(initialResults[1])
		else
			local connection
			connection = RunService.Heartbeat:Connect(function()
				local raycastResults = ProjectileShared.RaycastFromAttachments(Projectile, "ProjectileRay", Params)
				if raycastResults[1] then
					connection:Disconnect()
					resolve(raycastResults[1])
					return
				elseif Projectile.Parent ~= workspace then
					connection:Disconnect()
					reject("Projectile no longer in workspace.")
					return
				end
			end)
		end
	end)
end

function ProjectileShared.BlockcastProjectile(Projectile: BasePart, IgnoreList: {}?)
	local RaycastIgnoreList = IgnoreList or {}
	table.insert(RaycastIgnoreList, Projectile)

	local Params = RaycastParams.new()
	Params.FilterDescendantsInstances = RaycastIgnoreList
	Params.FilterType = Enum.RaycastFilterType.Exclude

	return Promise.new(function(resolve, reject, _onCancel)
		local heartbeatConnection
		heartbeatConnection = RunService.Heartbeat:Connect(function()
			local blockCastResult = workspace:Blockcast(
				Projectile.CFrame,
				Projectile:GetAttribute("ProjectileSize") or Projectile.Size,
				Projectile.CFrame.LookVector * 2,
				Params
			)
			if blockCastResult then
				heartbeatConnection:Disconnect()
				return resolve(blockCastResult)
			elseif Projectile:IsDescendantOf(workspace) == false then
				heartbeatConnection:Disconnect()
				return reject("Projectile no longer in workspace.")
			end
			return nil
		end)
	end)
end

function ProjectileShared.ShapecastProjectile(Projectile: BasePart, IgnoreList: {}?)
	local RaycastIgnoreList = IgnoreList or {}
	table.insert(RaycastIgnoreList, Projectile)

	local Params = RaycastParams.new()
	Params.FilterDescendantsInstances = RaycastIgnoreList
	Params.FilterType = Enum.RaycastFilterType.Exclude

	return Promise.new(function(resolve, reject, _onCancel)
		local heartbeatConnection
		heartbeatConnection = RunService.Heartbeat:Connect(function()
			local blockCastResult = workspace:Shapecast(Projectile, Projectile.CFrame.LookVector * 2, Params)
			if blockCastResult then
				heartbeatConnection:Disconnect()
				return resolve(blockCastResult)
			elseif Projectile:IsDescendantOf(workspace) == false then
				heartbeatConnection:Disconnect()
				return reject("Projectile no longer in workspace.")
			end
			return nil
		end)
	end)
end

function ProjectileShared.SpherecastProjectile(Projectile: BasePart, Radius: number, IgnoreList: {}?)
	local RaycastIgnoreList = IgnoreList or {}
	table.insert(RaycastIgnoreList, Projectile)

	local Params = RaycastParams.new()
	Params.FilterDescendantsInstances = RaycastIgnoreList
	Params.FilterType = Enum.RaycastFilterType.Exclude

	return Promise.new(function(resolve, reject, _onCancel)
		local heartbeatConnection
		heartbeatConnection = RunService.Heartbeat:Connect(function()
			local blockCastResult = workspace:Spherecast(Projectile.Position, Radius, Projectile.CFrame.LookVector * 2, Params)
			if blockCastResult then
				heartbeatConnection:Disconnect()
				return resolve(blockCastResult)
			elseif Projectile:IsDescendantOf(workspace) == false then
				heartbeatConnection:Disconnect()
				return reject("Projectile no longer in workspace.")
			end
			return nil
		end)
	end)
end

return ProjectileShared
