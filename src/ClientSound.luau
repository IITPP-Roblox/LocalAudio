--Instance of a sound on the client.
--!strict

local Workspace = game:GetService("Workspace")
local SoundService = game:GetService("SoundService")
local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")

local AudioData = require(script.Parent:WaitForChild("AudioData"))
local LocalAudioTypes = require(script.Parent:WaitForChild("LocalAudioTypes"))

local ClientSound = {}
ClientSound.InitialTimePositionIgnore = 0.5
ClientSound.__index = ClientSound

export type ClientSound = {
    Id: string,
    Parent: Instance?,
    ReplicationValue: StringValue,
    OnEvent: BindableEvent,
    SoundData: LocalAudioTypes.SoundDataEntry,
    Sound: Sound,
} & typeof(setmetatable({}, ClientSound))



--[[
Creates the client sound.
--]]
function ClientSound.new(Id: string, ReplicationValue: StringValue, Parent: Instance?, OnEvent: BindableEvent): ClientSound
    --Create the object.
    local self = setmetatable({
        Id = Id,
        Parent = Parent,
        ReplicationValue = ReplicationValue,
        OnEvent = OnEvent,
    }, ClientSound) :: ClientSound

    --Get the sound data.
    local SoundData = AudioData.Sounds
    for _, Tag in string.split(Id, ".") do
        SoundData = (SoundData :: LocalAudioTypes.SoundDataEntry)[Tag]
        if SoundData == nil then
            error(`Sound not found: {Id} at part {Tag}`)
        end
    end
    self.SoundData = SoundData :: LocalAudioTypes.SoundDataEntry

    --Create the sound.
    local SoundId = SoundData.Id
    if typeof(SoundId) ~= "string" then
        SoundId = `rbxassetid://{SoundId}`
    end
    local Sound = Instance.new("Sound")
    Sound.Name = string.gsub(Id, "%.", "")
    Sound.SoundId = SoundId :: string
    for Key, Value in (SoundData.Properties or {}) :: {[string]: any} do
        (Sound :: any)[Key] = Value
    end
    Sound.Parent = Parent or SoundService
    for _, Tag in (SoundData.Tags or {}) :: {string} do
        CollectionService:AddTag(Sound, Tag)
    end
    self.Sound = Sound

    --Connect the value changing.
    ReplicationValue.Changed:Connect(function()
        self:Update()
    end)
    self:Update()

    --Connect the value being destroyed (stopped).
    ReplicationValue.Destroying:Connect(function()
        self.Sound:Stop()
        self.Sound:Destroy()
    end)

    --Return the object.
    return self
end

--[[
Updates the sound based on the latest value.
--]]
function ClientSound.Update(self: ClientSound): ()
    --Read the replication data.
    local ReplicationData = HttpService:JSONDecode(self.ReplicationValue.Value)

    --Update the effects.
    local Effects = ReplicationData.Effects or {}
    for _, ExistingEffect in self.Sound:GetChildren() do
        if Effects[ExistingEffect.ClassName] then continue end
        ExistingEffect:Destroy()
    end
    for EffectType, EffectData in Effects do
        local ExistingEffect = self.Sound:FindFirstChildOfClass(EffectType) :: Instance
        if not ExistingEffect then
            ExistingEffect = Instance.new(EffectType)
        end
        for Key, Value in EffectData do
            (ExistingEffect :: any)[Key] = Value
        end
        ExistingEffect.Parent = self.Sound
    end

    --Update the sound state.
    if ReplicationData.State == "Play" and not self.Sound.Playing then
        --Determine the time position.
        --The time position is ignored if the sound was just started and is not looped.
        local TimePosition = Workspace:GetServerTimeNow() - ReplicationData.StartTime
        if TimePosition < self.InitialTimePositionIgnore then
            TimePosition = (self.SoundData.Properties and self.SoundData.Properties.TimePosition) or 0
        end
        if self.Sound.Looped then
            TimePosition = TimePosition % self.SoundData.Length
        end

        --Play the sound if the audio is still going.
        if TimePosition > self.SoundData.Length then return end
        self.Sound.TimePosition = TimePosition
        self.Sound:Play()

        --Start running events.
        if not self.SoundData.Events then return end
        table.sort(self.SoundData.Events, function(a: LocalAudioTypes.SoundDataEntryEvent, b: LocalAudioTypes.SoundDataEntryEvent)
            return a.Time < b.Time
        end)

        task.spawn(function()
            --Wait for the audio to load.
            if not self.Sound.IsLoaded then
                self.Sound.Loaded:Wait()
            end

            --Determine the event to start at.
            local LastEventTime = TimePosition
            local CurrentEventId = 1
            for i, Event in self.SoundData.Events do
                if Event.Time < TimePosition then
                    CurrentEventId = i + 1
                end
            end

            --Process events while the sound is playing.
            while self.Sound.Playing do
                --Get the current time and reset the last time if the audio looped.
                local CurrentEventTime = self.Sound.TimePosition
                if LastEventTime > CurrentEventTime and CurrentEventTime < 0.1 then
                    CurrentEventId = 1
                    LastEventTime = 0
                end

                --Process events until an event in the future is reached (or all events are reached).
                while true do
                    local CurrentEvent = self.SoundData.Events[CurrentEventId]
                    if not CurrentEvent or CurrentEvent.Time > CurrentEventTime then
                        break
                    elseif CurrentEvent.Time <= CurrentEventTime and CurrentEvent.Time >= LastEventTime then
                        self.OnEvent:Fire(self.Id, CurrentEvent, self.Parent, self.Sound)
                    end
                    CurrentEventId += 1
                end
                LastEventTime = CurrentEventTime
                task.wait()
            end
        end)
    elseif ReplicationData.State == "Stop" and self.Sound.Playing then
        self.Sound:Stop()
    end
end



return ClientSound