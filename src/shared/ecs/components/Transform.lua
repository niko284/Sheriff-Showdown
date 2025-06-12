local Matter = require("@packages/Matter")

local Transform = Matter.component("Transform", {
	cframe = CFrame.new(),
	doNotReconcile = false,
})

return Transform
