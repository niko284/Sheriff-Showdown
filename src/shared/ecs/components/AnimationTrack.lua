-- Animation Track

local Matter = require("@packages/Matter")

local AnimationTrack = Matter.component("AnimationTrack", {
	track = nil :: AnimationTrack?,
	looped = false,
	speed = 1,
	played = false,
})

return AnimationTrack
