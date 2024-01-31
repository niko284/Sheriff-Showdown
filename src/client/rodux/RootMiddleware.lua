-- Root Middleware
-- January 22nd, 2024
-- Nick

-- // Variables \\

local Middleware = script.Parent.middleware

-- // Root Reducer \\

local RootMiddleware = {}

for _, MiddlewareModule: Instance in Middleware:GetChildren() do
	if MiddlewareModule:IsA("ModuleScript") then
		local MiddlewareFn = require(MiddlewareModule)
		table.insert(RootMiddleware, MiddlewareFn)
	end
end

return RootMiddleware
