--[[
TheNexusAvenger

Sets up the LocalAudio module.
--]]

local LocalAudio = require(game:GetService("ReplicatedStorage"):WaitForChild("LocalAudio"))
LocalAudio:SetUp()

LocalAudio.OnEvent:Connect(function(Id, Event, Parent, Sound)
    if not Parent then return end
    if Event.Name == "CheerStart" then
        Parent.BrickColor = BrickColor.random()
    elseif Event.Name == "CheerSecond" then
        Parent.BrickColor = BrickColor.random()
    end
end)

LocalAudio:OnEventFired("CheerStart"):Connect(function(_, _, Parent, Sound)
    print("Cheer sound started on "..tostring(Parent).." in "..tostring(Sound))
end)

game:GetService("CollectionService"):GetInstanceAddedSignal("TestTag"):Connect(function(Sound)
    print("Sound tagged: "..Sound:GetFullName())
end)