-- Animation Track

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Matter = require(ReplicatedStorage.packages.Matter)

local AnimationTrack = Matter.component("AnimationTrack", {
	track = nil :: AnimationTrack?,
	looped = false,
	speed = 1,
	played = false,
})

return AnimationTrack
