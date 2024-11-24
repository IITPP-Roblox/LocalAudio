--Tests playing global audios.
--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalAudio = require(ReplicatedStorage:WaitForChild("LocalAudio"))



while true do
    LocalAudio:PlayAudio("Demo.Global")
    task.wait(1)
end