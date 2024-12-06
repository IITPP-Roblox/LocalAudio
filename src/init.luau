--Plays audios locally.
--!strict

local ContentProvider = game:GetService("ContentProvider")
local RunService = game:GetService("RunService")

local AudioData = require(script:WaitForChild("AudioData"))
local LocalAudioTypes = require(script:WaitForChild("LocalAudioTypes"))

local LocalAudio = {}
LocalAudio.PreloadedAudios = {}

export type LocalAudio = typeof(LocalAudio)



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

    if not _G.LocalAudioSingletonEvents then
        local LocalAudioSingletonEvents = {}
        _G.LocalAudioSingletonEvents = LocalAudioSingletonEvents
        LocalAudioSingletonEvents.OnEventBindableEvent = Instance.new("BindableEvent")
        LocalAudioSingletonEvents.OnEvent = LocalAudioSingletonEvents.OnEventBindableEvent.Event
        LocalAudioSingletonEvents.NameEvents = {}

        LocalAudioSingletonEvents.OnEvent:Connect(function(Id: string, Event: LocalAudioTypes.SoundDataEntryEvent, Parent: Instance?, Sound: Sound)
            if not Event.Name then return end
            if not LocalAudioSingletonEvents.NameEvents[Event.Name] then return end
            LocalAudioSingletonEvents.NameEvents[Event.Name]:Fire(Id, Event, Parent, Sound)
        end)
    end
    LocalAudio.OnEventBindableEvent = _G.LocalAudioSingletonEvents.OnEventBindableEvent
    LocalAudio.OnEvent = _G.LocalAudioSingletonEvents.OnEvent
    LocalAudio.NameEvents = _G.LocalAudioSingletonEvents.NameEvents

    PreloadAudioEvent = script:WaitForChild("PreloadAudio")
    CurrentAudioFolder = script:WaitForChild("CurrentAudio")
end

local ClientSound = require(script:WaitForChild("ClientSound"))
local SoundState = require(script:WaitForChild("SoundState"))



--[[
Returns if an audio is part of a group.
--]]
local function IsInGroup(Id: string, Group: string): boolean
    return Id == Group or string.sub(Id, 1, string.len(Group) + 1) == `{Group}.`
end

--[[
Connects a parent of values.
--]]
local function ConnectParent(Parent: Instance): ()
    --Wait for the instance to exist.
    if Parent:IsA("ObjectValue") then
        while not Parent.Value do
            Parent:GetPropertyChangedSignal("Value"):Wait()
        end
    end

    --Connect values being added.
    local SoundPart = (Parent:IsA("ObjectValue") and Parent.Value or nil)
    Parent.ChildAdded:Connect(function(ChildValue)
        --OpenSlot is called in case the client has started an audio before the server plays a new one.
        LocalAudio:OpenSlot(ChildValue.Name, true)
        if not ChildValue:IsA("StringValue") then return end
        ClientSound.new(ChildValue.Name, ChildValue, SoundPart, LocalAudio.OnEventBindableEvent)
    end)
    for _, ChildValue in Parent:GetChildren() do
        if not ChildValue:IsA("StringValue") then continue end
        ClientSound.new(ChildValue.Name, ChildValue, SoundPart, LocalAudio.OnEventBindableEvent)
    end
end



--[[
Preloads an audio on the client.
--]]
function LocalAudio.PreloadAudio(self: LocalAudio, Id: string): ()
    if RunService:IsServer() then
        --Tell the clients to preload the audio.
        PreloadAudioEvent:FireAllClients(Id)
    else
        --Preload the audio.
        local SoundId = SoundState.GetSoundData(Id).Id
        if typeof(SoundId) ~= "string" then
            SoundId = `rbxassetid://{SoundId}`
        end
        local SoundIdString = SoundId :: string
        if self.PreloadedAudios[SoundIdString] then return end
        self.PreloadedAudios[SoundIdString] = true

        local Sound = Instance.new("Sound")
        Sound.SoundId = SoundIdString
        ContentProvider:PreloadAsync({Sound})
    end
end

--[[
Returns the StringValues of the audios playing for the group.
--]]
function LocalAudio.GetValuesInGroup(self: LocalAudio, Group: string): {StringValue}
    local SoundValues = {}
    for _, ValueContainer in CurrentAudioFolder:GetChildren() do
        for _, SoundValue in ValueContainer:GetChildren() do
            if not IsInGroup(SoundValue.Name, Group) then continue end
            if not SoundValue:IsA("StringValue") then continue end
            table.insert(SoundValues, SoundValue)
        end
    end
    return SoundValues
end

--[[
Returns if there is an open slot for the given id or group.
--]]
function LocalAudio.HasOpenSlot(self: LocalAudio, IdOrGroup: string): boolean
    for Group, Limit in (AudioData.MaxConcurrentTracks or {}) :: {[string]: number} do
        if not IsInGroup(IdOrGroup, Group) then continue end
        if #self:GetValuesInGroup(Group) < Limit then continue end
        return false
    end
    return true
end

--[[
Opens a slot for the given audio id to be played. Does nothing if there are no limits.
--]]
function LocalAudio.OpenSlot(self: LocalAudio, Id: string, LeaveAtLimit: boolean?): ()
    for Group, Limit in (AudioData.MaxConcurrentTracks or {}) :: {[string]: number} do
        if not IsInGroup(Id, Group) then continue end
        local SoundValues = self:GetValuesInGroup(Group)
        while #SoundValues >= (LeaveAtLimit and Limit + 1 or Limit) do
            local SoundValue = SoundValues[1]
            if SoundState.ActiveSoundStates[SoundValue] then
                SoundState.ActiveSoundStates[SoundValue]:Stop()
            end
            SoundValue:Destroy()
            table.remove(SoundValues, 1)
        end
    end
end

--[[
Plays an audio on the client.
--]]
function LocalAudio.PlayAudio(self: LocalAudio,Id: string, Parent: Instance?): ()
    --Return if the audio is not able to open a slot.
    local SoundData = SoundState.GetSoundData(Id)
    if SoundData.LowPriority and not self:HasOpenSlot(Id) then
        return
    end

    --Play the new audio.
    SoundState.new(Id, Parent)
end

--[[
Reumes an audio on the client.
--]]
function LocalAudio.ResumeAudio(self: LocalAudio,Id: string, Parent: Instance?): ()
    local ValueContainer = SoundState.GetValueContainer(Parent)
    for _, SoundValue in ValueContainer:GetChildren() do
        if not SoundValue:IsA("StringValue") then continue end
        local StateObject = SoundState.ActiveSoundStates[SoundValue]
        if SoundValue.Name ~= Id then continue end
        if not StateObject or StateObject.State.State ~= "Stop" then continue end
        StateObject:Resume()
        break
    end
end

--[[
Pauses an audio on the client.
--]]
function LocalAudio.PauseAudio(self: LocalAudio,Id: string, Parent: Instance?): ()
    local ValueContainer = SoundState.GetValueContainer(Parent)
    for _, SoundValue in ValueContainer:GetChildren() do
        if not SoundValue:IsA("StringValue") then continue end
        local StateObject = SoundState.ActiveSoundStates[SoundValue]
        if SoundValue.Name ~= Id then continue end
        if not StateObject or StateObject.State.State ~= "Play" then continue end
        StateObject:Pause()
        break
    end
end

--[[
Stops an audio on the client.
--]]
function LocalAudio.StopAudio(self: LocalAudio,Id: string, Parent: Instance?): ()
    local ValueContainer = SoundState.GetValueContainer(Parent)
    for _, SoundValue in ValueContainer:GetChildren() do
        if not SoundValue:IsA("StringValue") then continue end
        if SoundValue.Name ~= Id then continue end
        if SoundState.ActiveSoundStates[SoundValue] then
            SoundState.ActiveSoundStates[SoundValue]:Stop()
        end
        SoundValue:Destroy()
        break
    end
end

--[[
Sets the effects for a sound.
--]]
function LocalAudio.SetEffects(self: LocalAudio,Id: string, Parent: Instance?, Effects: {[string]: {[string]: any}}): ()
    local ValueContainer = SoundState.GetValueContainer(Parent)
    for _, SoundValue in ValueContainer:GetChildren() do
        if not SoundValue:IsA("StringValue") then continue end
        local StateObject = SoundState.ActiveSoundStates[SoundValue]
        if SoundValue.Name ~= Id then continue end
        if not StateObject or StateObject.State.State ~= "Play" then continue end
        StateObject:SetEffects(Effects)
    end
end

--[[
Returns an event specific to the an event of a specific name being fired.
--]]
function LocalAudio.OnEventFired(self: LocalAudio,Name: string): RBXScriptSignal
    if not self.NameEvents[Name] then
        self.NameEvents[Name] = Instance.new("BindableEvent")
    end
    return self.NameEvents[Name].Event
end

--[[
Sets up the sounds on the client.
--]]
function LocalAudio.SetUp(self: LocalAudio): ()
    --Connect preloading audios.
    PreloadAudioEvent.OnClientEvent:Connect(function(Id: string)
        self:PreloadAudio(Id)
    end)

    --Set up values being created (sounds being played).
    CurrentAudioFolder.ChildAdded:Connect(ConnectParent)
    for _, ValueParent in CurrentAudioFolder:GetChildren() do
        task.spawn(function()
            ConnectParent(ValueParent)
        end)
    end
end



return LocalAudio