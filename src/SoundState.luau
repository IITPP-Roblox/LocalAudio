--Manages the state of sounds.
--!strict

local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")

local AudioData = require(script.Parent:WaitForChild("AudioData"))
local LocalAudioTypes = require(script.Parent:WaitForChild("LocalAudioTypes"))

local SoundState = {}
SoundState.AutomaticClearDelay = 3 --An additional delay is added to clearing audios to mitigate audios cutting out on the client.
SoundState.__index = SoundState

local CurrentAudioFolder = script.Parent:WaitForChild("CurrentAudio")

export type SoundStateEnum = "Play" | "Stop"
export type SoundState = {
    SoundData: LocalAudioTypes.SoundDataEntry,
    State: {
        StartTime: number,
        State: SoundStateEnum,
        Effects: {[string]: {[string]: any}}?,
    },
    EventConnections: {RBXScriptConnection},
    StateValue: StringValue,
    LastSaveTime: number?,
    PauseElapsedTime: number?,
} & typeof(setmetatable({}, SoundState))



--[[
Returns the container for a sound parent.
--]]
function SoundState.GetValueContainer(Parent: Instance?): Instance
    local ValueParent: Instance? = nil
    if Parent then
        for _, ValueObject in CurrentAudioFolder:GetChildren() do
            if ValueObject:IsA("ObjectValue") and ValueObject.Value == Parent then
                return ValueObject
            end
        end
        local NewValueParent = Instance.new("ObjectValue")
        NewValueParent.Name = Parent.Name
        NewValueParent.Value = Parent
        NewValueParent.Parent = CurrentAudioFolder
        ValueParent = NewValueParent
    else
        ValueParent = CurrentAudioFolder:FindFirstChildOfClass("Folder")
        if not ValueParent then
            local NewValueParent = Instance.new("Folder")
            NewValueParent.Name = "Global"
            NewValueParent.Parent = CurrentAudioFolder
            ValueParent = NewValueParent
        end
    end
    return ValueParent :: Instance
end

--[[
Returns the sound data for a given id.
--]]
function SoundState.GetSoundData(Id: string): LocalAudioTypes.SoundDataEntry
    local SoundData = AudioData.Sounds
    for _, Tag in string.split(Id, ".") do
        SoundData = SoundData[Tag]
        if SoundData == nil then
            error(`Sound not found: {Id} at part {Tag}`)
        end
    end
    return SoundData
end

--[[
Creates the sound state.
--]]
function SoundState.new(Id: string, Parent: Instance?): SoundState
    --Create the object.
    local SoundData = SoundState.GetSoundData(Id)
    local self = setmetatable({
        SoundData = SoundData,
        State = {
            StartTime = Workspace:GetServerTimeNow(),
            State = "Play" :: SoundStateEnum,
            Effects = SoundData.Effects,
        },
        EventConnections = {},
    }, SoundState) :: SoundState

    --Create the value.
    local ValueParent = SoundState.GetValueContainer(Parent)
    local StateValue = Instance.new("StringValue")
    StateValue.Name = Id
    self.StateValue = StateValue
    self:Play()
    StateValue.Parent = ValueParent

    --Connect the parent destroying.
    if Parent then
        table.insert(self.EventConnections, Parent.Destroying:Connect(function()
            self:Stop()
            ValueParent:Destroy()
        end))
    end

    --Return the object.
    return self :: any
end

--[[
Saves the state.
--]]
function SoundState.Save(self: SoundState): ()
    --Save the state.
    local LastSaveTime = tick()
    self.StateValue.Value = HttpService:JSONEncode(self.State)
    self.LastSaveTime = LastSaveTime

    --Clear the sound after it completes.
    if self.SoundData.Properties and self.SoundData.Properties.Looped then return end
    if self.State.State ~= "Play" then return end
    local DurationMultiplier = (self.SoundData.Properties and (1 / (self.SoundData.Properties.PlaybackSpeed or 1)) or 1)
    local RemainingTime = (self.SoundData.Length * DurationMultiplier) - (Workspace:GetServerTimeNow() - self.State.StartTime) + self.AutomaticClearDelay
    task.delay(RemainingTime, function()
        if self.LastSaveTime ~= LastSaveTime then return end
        self:Stop()
    end)
end

--[[
Plays the audio.
--]]
function SoundState.Play(self: SoundState): ()
    self.State.State = "Play"
    self.State.StartTime = Workspace:GetServerTimeNow() - ((self.SoundData.Properties and self.SoundData.Properties.TimePosition) or 0)
    self.PauseElapsedTime = nil
    self:Save()
end

--[[
Resumes the audio.
--]]
function SoundState.Resume(self: SoundState): ()
    if self.State.State == "Play" then return end
    self.State.State = "Play"
    self.State.StartTime = Workspace:GetServerTimeNow() - (self.PauseElapsedTime or 0)
    self.PauseElapsedTime = nil
    self:Save()
end

--[[
Pauses the audio.
--]]
function SoundState.Pause(self: SoundState): ()
    if self.State.State == "Stop" then return end
    self.State.State = "Stop"
    self.PauseElapsedTime = (Workspace:GetServerTimeNow() - self.State.StartTime) % self.SoundData.Length
    self:Save()
end

--[[
Stops the audio.
--]]
function SoundState.Stop(self: SoundState): ()
    if self.State.State == "Stop" then return end
    self.State.State = "Stop"
    self:Save()
    self.StateValue:Destroy()

    for _, EventConnection in self.EventConnections do
        EventConnection:Disconnect()
    end
    self.EventConnections = {}
end

--[[
Sets the effects of the audio.
--]]
function SoundState.SetEffects(self: SoundState, Effects: {[string]: {[string]: any}}): ()
    self.State.Effects = Effects
    self:Save()
end



return SoundState