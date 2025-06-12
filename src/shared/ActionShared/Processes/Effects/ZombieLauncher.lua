--!strict

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = ReplicatedStorage:FindFirstChild("assets") :: Folder
local Effects = Assets:FindFirstChild("effects") :: Folder

local AudioUtils = require("@utilities/AudioUtils")
local Audios = require("@constants/Audios")
local Types = require("@constants/Types")

local ZombieLauncher = {} :: Types.Effect
ZombieLauncher.Name = "Zombie Launcher"

local ZOMBIE_MESH = Effects:FindFirstChild("Zombie") :: MeshPart
local ZOMBIE_DURATION = 3.8
local RANDOM_PRESETS = {
	"Zombie1",
	"Zombie2",
	"Zombie3",
	"Zombie4",
	"Zombie5",
}

function ZombieLauncher.ApplyKillEffect(KilledEntity: Model)
	local zombie = ZOMBIE_MESH:Clone()
	zombie:PivotTo(KilledEntity:GetPivot() * CFrame.new(0, 5, 0))
	zombie.Parent = workspace

	local randomPreset = Audios[RANDOM_PRESETS[math.random(1, #RANDOM_PRESETS)]]
	AudioUtils.PlayPreset(randomPreset, zombie)

	Debris:AddItem(zombie, ZOMBIE_DURATION)
end

return ZombieLauncher
