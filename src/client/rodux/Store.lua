-- Store
-- January 22nd, 2024
-- Nick

-- // Variables \\

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Rodux = require(ReplicatedStorage.packages.Rodux)
local RootMiddleware = require(script.Parent.RootMiddleware)
local RootReducer = require(script.Parent.RootReducer)

local Store = Rodux.Store

-- // Store \\

return Store.new(RootReducer, {}, RootMiddleware)
