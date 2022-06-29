--[[
TheNexusAvenger

Tests playing global audios.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalAudio = require(ReplicatedStorage:WaitForChild("LocalAudio"))



while true do
    LocalAudio:PlayAudio("Demo.Global")
    task.wait(1)
end