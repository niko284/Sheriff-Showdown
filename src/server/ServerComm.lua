local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.packages

local ServerComm = require(Packages.Comm).ServerComm

return ServerComm.new(ReplicatedStorage.comm, "GameComm")
