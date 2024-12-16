--!strict

local actions = {}
for _, actionModule in script:GetChildren() do
	if actionModule:IsA("ModuleScript") then
		local action = require(actionModule) :: any
		actions[actionModule.Name] = action
	end
end

return actions
