-- Nametag Controller
-- September 22nd, 2022
-- Nick

-- // Variables \\

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.packages
local Components = ReplicatedStorage.components
local Constants = ReplicatedStorage.constants
local Utils = ReplicatedStorage.utils

local InstanceUtils = require(Utils.InstanceUtils)
local Nametag = require(Components.common.Nametag)
local Promise = require(Packages.Promise)
local React = require(Packages.React)
local ReactRoblox = require(Packages.ReactRoblox)
local Types = require(Constants.Types)

local e = React.createElement

-- // Controller Variables \\

local NametagController = {
	Name = "NametagController",
	NametagTrees = {},
}

-- // Functions \\

type NametagInfo = {
	target: BasePart,
	userId: number?,
	name: string,
	studsOffset: Vector3?,
	size: UDim2,
	level: number,
}

function NametagController:DestroyNametag(Entity: Types.Entity)
	local tree = self.NametagTrees[Entity]
	if tree then
		tree:unmount()
		self.NametagTrees[Entity] = nil
	end
end

function NametagController:CreateEntityNametag(Entity: Types.Entity)
	local PlayerEntity = Players:GetPlayerFromCharacter(Entity)

	if PlayerEntity and PlayerEntity:HasAppearanceLoaded() == false then
		PlayerEntity.CharacterAppearanceLoaded:Wait()
	end

	Promise.all({
		InstanceUtils.WaitForChildOfClass(Entity, "Humanoid"),
		InstanceUtils.WaitForChild(Entity, "Head", "BasePart"),
	}):andThen(function(results)
		local Humanoid = results[1]
		local Head = results[2]

		Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None

		self.NametagTrees[Entity] = NametagController:BuildNametag({
			target = Head,
			userId = PlayerEntity and PlayerEntity.UserId,
			name = PlayerEntity and PlayerEntity.Name or Entity.Name,
			studsOffset = Vector3.new(0, 1.7, 0),
			size = UDim2.fromScale(3.9, 1),
			level = PlayerEntity and PlayerEntity:GetAttribute("Level") or "-",
			entity = Entity,
		}, Head) -- We store the RoactTree to unmount it when the player dies or leaves the game.
	end)
end

function NametagController:BuildNametag(Info: NametagInfo, Parent: Instance): ReactRoblox.RootType
	local nametagElement = e(Nametag, Info)
	local root = ReactRoblox.createRoot(Instance.new("Folder"))
	root:render(ReactRoblox.createPortal({ nametagElement }, Parent))
	return root
end

return NametagController
