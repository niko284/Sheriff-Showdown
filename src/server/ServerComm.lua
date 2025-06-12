local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ServerComm = require("@packages/Comm").ServerComm

return ServerComm.new(ReplicatedStorage.comm, "GameComm")
