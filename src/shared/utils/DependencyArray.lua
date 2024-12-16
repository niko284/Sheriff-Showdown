--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.packages

local Symbol = require(Packages.Symbol)

local NilSymbol = Symbol("NilDependency")

return function(...)
	local dependencyArray = {}
	local length = select("#", ...)
	for i = 1, length do
		local dependency = select(i, ...)
		if dependency == nil then
			dependency = NilSymbol
		end
		dependencyArray[i] = dependency
	end
	return dependencyArray
end
