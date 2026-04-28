--!strict

local CollectionService = game:GetService("CollectionService")

local jecs = require("@packages/jecs")

local SettingsController = require("@controllers/SettingsController")

-- Team highlight creation/removal is handled by Team OnAdd/OnChange/OnRemove observers
-- in client/ecs/observers.lua. This system only syncs transparency when the setting changes.

local lastTransparency = -1

local function teamsAreHighlighted(_world: jecs.World)
	local current = (SettingsController:GetSetting("Team Outlines").Value :: number) / 100
	if current == lastTransparency then
		return
	end
	lastTransparency = current
	for _, highlight in CollectionService:GetTagged("TeamHighlight") do
		if highlight:IsA("Highlight") then
			(highlight :: Highlight).OutlineTransparency = current
		end
	end
end

return teamsAreHighlighted
