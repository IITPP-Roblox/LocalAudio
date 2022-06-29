--[[
TheNexusAvenger

Plays audios locally.
--]]

local ContentProvider = game:GetService("ContentProvider")
local RunService = game:GetService("RunService")

local AudioData = require(script:WaitForChild("AudioData"))

local LocalAudio = {}
LocalAudio.PreloadedAudios = {}
LocalAudio.ValuesToStateObjects = {}
setmetatable(LocalAudio.ValuesToStateObjects, {__mode="k"})



--Create the replication event and state value.
local PreloadAudioEvent = nil
local CurrentAudioFolder = nil
if RunService:IsServer() then
    PreloadAudioEvent = Instance.new("RemoteEvent")
    PreloadAudioEvent.Name = "PreloadAudio"
    PreloadAudioEvent.Parent = script

    CurrentAudioFolder = Instance.new("Folder")
    CurrentAudioFolder.Name = "CurrentAudio"
    CurrentAudioFolder.Parent = script
else
    PreloadAudioEvent = script:WaitForChild("PreloadAudio")
    CurrentAudioFolder = script:WaitForChild("CurrentAudio")
end

local ClientSound = require(script:WaitForChild("ClientSound"))
local SoundState = require(script:WaitForChild("SoundState"))



--[[
Returns if an audio is part of a group.
--]]
local function IsInGroup(Id: string, Group: string): boolean
    return Id == Group or string.sub(Id, 1, string.len(Group) + 1) == Group.."."
end

--[[
Connects a parent of values.
--]]
local function ConnectParent(Parent: Instance): nil
    --Wait for the instance to exist.
    if Parent:IsA("ObjectValue") then
        while not Parent.Value do
            Parent:GetPropertyChangedSignal("Value"):Wait()
        end
    end

    --Connect values being added.
    local SoundPart = (Parent:IsA("ObjectValue") and Parent.Value)
    Parent.ChildAdded:Connect(function(ChildValue)
        --OpenSlot is called in case the client has started an audio before the server plays a new one.
        LocalAudio:OpenSlot(ChildValue.Name, true)
        ClientSound.new(ChildValue.Name, ChildValue, SoundPart)
    end)
    for _, ChildValue in pairs(Parent:GetChildren()) do
        ClientSound.new(ChildValue.Name, ChildValue, SoundPart)
    end
end



--[[
Preloads an audio on the client.
--]]
function LocalAudio:PreloadAudio(Id: string): nil
    if RunService:IsServer() then
        --Tell the clients to preload the audio.
        PreloadAudioEvent:FireAllClients(Id)
    else
        --Preload the audio.
        local SoundId = "rbxassetid://"..tostring(SoundState.GetSoundData(Id).Id)
        if self.PreloadedAudios[SoundId] then return end
        self.PreloadedAudios[SoundId] = true

        local Sound = Instance.new("Sound")
        Sound.SoundId = SoundId
        ContentProvider:PreloadAsync({Sound})
    end
end

--[[
Returns the StringValues of the audios playing for the group.
--]]
function LocalAudio:GetValuesInGroup(Group: string): {StringValue}
    local SoundValues = {}
    for _, ValueContainer in pairs(CurrentAudioFolder:GetChildren()) do
        for _, SoundValue in pairs(ValueContainer:GetChildren()) do
            if not IsInGroup(SoundValue.Name, Group) then continue end
            table.insert(SoundValues, SoundValue)
        end
    end
    return SoundValues
end

--[[
Returns if there is an open slot for the given id or group.
--]]
function LocalAudio:HasOpenSlot(IdOrGroup: string): boolean
    for Group, Limit in pairs(AudioData.MaxConcurrentTracks or {}) do
        if not IsInGroup(IdOrGroup, Group) then continue end
        if #self:GetValuesInGroup(Group) < Limit then continue end
        return false
    end
    return true
end

--[[
Opens a slot for the given audio id to be played. Does nothing if there are no limits.
--]]
function LocalAudio:OpenSlot(Id: string, LeaveAtLimit: boolean?): nil
    for Group, Limit in pairs(AudioData.MaxConcurrentTracks or {}) do
        if not IsInGroup(Id, Group) then continue end
        local SoundValues = self:GetValuesInGroup(Group)
        while #SoundValues >= (LeaveAtLimit and Limit + 1 or Limit) do
            local SoundValue = SoundValues[1]
            if self.ValuesToStateObjects[SoundValue] then
                self.ValuesToStateObjects[SoundValue]:Stop()
            end
            SoundValue:Destroy()
            table.remove(SoundValues, 1)
        end
    end
end

--[[
Plays an audio on the client.
--]]
function LocalAudio:PlayAudio(Id: string, Parent: Instance?): nil
    --Return if the audio is not able to open a slot.
    local SoundData = SoundState.GetSoundData(Id)
    if SoundData.LowPriority and not self:HasOpenSlot(Id) then
        return
    end

    --Play the new audio.
    local Sound = SoundState.new(Id, Parent)
    self.ValuesToStateObjects[Sound.StateValue] = Sound
end

--[[
Reumes an audio on the client.
--]]
function LocalAudio:ResumeAudio(Id: string, Parent: Instance?): nil
    local ValueContainer = SoundState.GetValueContainer(Parent)
    for _, SoundValue in pairs(ValueContainer:GetChildren()) do
        local StateObject = self.ValuesToStateObjects[SoundValue]
        if SoundValue.Name ~= Id then continue end
        if not StateObject or StateObject.State.State ~= "Stop" then continue end
        StateObject:Resume()
        break
    end
end

--[[
Pauses an audio on the client.
--]]
function LocalAudio:PauseAudio(Id: string, Parent: Instance?): nil
    local ValueContainer = SoundState.GetValueContainer(Parent)
    for _, SoundValue in pairs(ValueContainer:GetChildren()) do
        local StateObject = self.ValuesToStateObjects[SoundValue]
        if SoundValue.Name ~= Id then continue end
        if not StateObject or StateObject.State.State ~= "Play" then continue end
        StateObject:Pause()
        break
    end
end

--[[
Stops an audio on the client.
--]]
function LocalAudio:StopAudio(Id: string, Parent: Instance?): nil
    local ValueContainer = SoundState.GetValueContainer(Parent)
    for _, SoundValue in pairs(ValueContainer:GetChildren()) do
        if SoundValue.Name ~= Id then continue end
        if self.ValuesToStateObjects[SoundValue] then
            self.ValuesToStateObjects[SoundValue]:Stop()
        end
        SoundValue:Destroy()
        break
    end
end

--[[
Sets the effects for a sound.
--]]
function LocalAudio:SetEffects(Id: string, Parent: Instance?, Effects: {[string]: {[string]: any}}): nil
    local ValueContainer = SoundState.GetValueContainer(Parent)
    for _, SoundValue in pairs(ValueContainer:GetChildren()) do
        local StateObject = self.ValuesToStateObjects[SoundValue]
        if SoundValue.Name ~= Id then continue end
        if not StateObject or StateObject.State.State ~= "Play" then continue end
        StateObject:SetEffects(Effects)
    end
end

--[[
Sets up the sounds on the client.
--]]
function LocalAudio:SetUp(): nil
    --Connect preloading audios.
    PreloadAudioEvent.OnClientEvent:Connect(function(Id: string)
        self:PreloadAudio(Id)
    end)

    --Set up values being created (sounds being played).
    CurrentAudioFolder.ChildAdded:Connect(ConnectParent)
    for _, ValueParent in pairs(CurrentAudioFolder:GetChildren()) do
        task.spawn(function()
            ConnectParent(ValueParent)
        end)
    end
end



return LocalAudio