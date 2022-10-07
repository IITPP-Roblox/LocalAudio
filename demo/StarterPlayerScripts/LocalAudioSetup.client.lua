--[[
TheNexusAvenger

Sets up the LocalAudio module.
--]]

local LocalAudio = require(game:GetService("ReplicatedStorage"):WaitForChild("LocalAudio"))
LocalAudio:SetUp()

LocalAudio.OnEvent:Connect(function(Id, Event, Parent)
    if not Parent then return end
    if Event.Name == "CheerStart" then
        Parent.BrickColor = BrickColor.random()
    elseif Event.Name == "CheerSecond" then
        Parent.BrickColor = BrickColor.random()
    end
end)

LocalAudio:OnEventFired("CheerStart"):Connect(function(_, _, Parent)
    print("Cheer sound started on "..tostring(Parent))
end)