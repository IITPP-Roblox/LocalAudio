--[[
TheNexusAvenger

Tests playing audios local to a source.
--]]

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalAudio = require(ReplicatedStorage:WaitForChild("LocalAudio"))
local TestModels = Workspace:WaitForChild("TestModels")
local TestParts = {
    TestModels:WaitForChild("Part1"),
    TestModels:WaitForChild("Part2"),
    TestModels:WaitForChild("Part3"),
    TestModels:WaitForChild("Part4"),
}



LocalAudio:PlayAudio("Demo.LocalLooped", TestModels:WaitForChild("Part5"))
while true do
    for _, TestPart in pairs(TestParts) do
        LocalAudio:PlayAudio("Demo.Local", TestPart)
        task.wait(1.2)
        LocalAudio:StopAudio("Demo.Local", TestPart)
    end
end