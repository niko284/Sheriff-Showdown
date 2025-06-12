--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClientComm = require("@packages/Comm").ClientComm

return ClientComm.new(ReplicatedStorage:FindFirstChild("comm") :: Folder, false, "GameComm")
