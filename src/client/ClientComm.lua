-- Client Comm
-- August 17th, 2022
-- Nick

-- // Variables \\

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.packages

local ClientComm = require(Packages.Comm).ClientComm

return ClientComm.new(ReplicatedStorage.comm, false, "GameComm")
