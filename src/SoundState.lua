--[[
TheNexusAvenger

Manages the state of sounds.
--]]

local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")

local AudioData = require(script.Parent:WaitForChild("AudioData"))
local LocalAudioTypes = require(script.Parent:WaitForChild("LocalAudioTypes"))

local SoundState = {}
SoundState.__index = SoundState

local CurrentAudioFolder = script.Parent:WaitForChild("CurrentAudio")



--[[
Returns the container for a sound parent.
--]]
function SoundState.GetValueContainer(Parent: Instance?): Instance
    local ValueParent = nil
    if Parent then
        for _, ValueObject in pairs(CurrentAudioFolder:GetChildren()) do
            if ValueObject:IsA("ObjectValue") and ValueObject.Value == Parent then
                return ValueObject
            end
        end
        ValueParent = Instance.new("ObjectValue")
        ValueParent.Name = Parent.Name
        ValueParent.Value = Parent
        ValueParent.Parent = CurrentAudioFolder
    else
        ValueParent = CurrentAudioFolder:FindFirstChildOfClass("Folder")
        if not ValueParent then
            ValueParent = Instance.new("Folder")
            ValueParent.Name = "Global"
            ValueParent.Parent = CurrentAudioFolder
        end
    end
    return ValueParent
end

--[[
Returns the sound data for a given id.
--]]
function SoundState.GetSoundData(Id: string): LocalAudioTypes.SoundDataEntry
    local SoundData = AudioData.Sounds
    for _, Tag in pairs(string.split(Id, ".")) do
        SoundData = SoundData[Tag]
        if SoundData == nil then
            error("Sound not found: "..Id.." at part "..Tag)
        end
    end
    return SoundData
end

--[[
Creates the sound state.
--]]
function SoundState.new(Id: string, Parent: Instance?): LocalAudioTypes.SoundState
    --Create the object.
    local self = {}
    setmetatable(self, SoundState)

    --Get the sound data.
    local SoundData = SoundState.GetSoundData(Id)
    self.SoundData = SoundData

    --Build the state.
    local State = {
        StartTime = Workspace:GetServerTimeNow(),
        State = "Play",
        Effects = SoundData.Effects,
    }
    self.State = State

    --Create the value.
    local ValueParent = SoundState.GetValueContainer(Parent)
    local StateValue = Instance.new("StringValue")
    StateValue.Name = Id
    self.StateValue = StateValue
    self:Play()
    StateValue.Parent = ValueParent

    --Return the object.
    return self
end

--[[
Saves the state.
--]]
function SoundState:Save(): nil
    --Save the state.
    local LastSaveTime = tick()
    self.StateValue.Value = HttpService:JSONEncode(self.State)
    self.LastSaveTime = LastSaveTime

    --Clear the sound after it completes.
    if self.SoundData.Properties and self.SoundData.Properties.Looped then return end
    if self.State.State ~= "Play" then return end
    local DurationMultiplier = (self.SoundData.Properties and (1 / (self.SoundData.Properties.PlaybackSpeed or 1)) or 1)
    local RemainingTime = (self.SoundData.Length * DurationMultiplier) - (Workspace:GetServerTimeNow() - self.State.StartTime)
    task.delay(RemainingTime, function()
        if self.LastSaveTime ~= LastSaveTime then return end
        self:Stop()
    end)
end

--[[
Plays the audio.
--]]
function SoundState:Play(): nil
    self.State.State = "Play"
    self.State.StartTime = Workspace:GetServerTimeNow() - ((self.SoundData.Properties and self.SoundData.Properties.TimePosition) or 0)
    self.PauseElapsedTime = nil
    self:Save()
end

--[[
Resumes the audio.
--]]
function SoundState:Resume(): nil
    if self.State.State == "Play" then return end
    self.State.State = "Play"
    self.State.StartTime = Workspace:GetServerTimeNow() - (self.PauseElapsedTime or 0)
    self.PauseElapsedTime = nil
    self:Save()
end

--[[
Pauses the audio.
--]]
function SoundState:Pause(): nil
    if self.State.State == "Stop" then return end
    self.State.State = "Stop"
    self.PauseElapsedTime = (Workspace:GetServerTimeNow() - self.State.StartTime) % self.SoundData.Length
    self:Save()
end

--[[
Stops the audio.
--]]
function SoundState:Stop(): nil
    if self.State.State == "Stop" then return end
    self.State.State = "Stop"
    self:Save()
    self.StateValue:Destroy()
end

--[[
Sets the effects of the audio.
--]]
function SoundState:SetEffects(Effects: {[string]: {[string]: any}}): nil
    self.State.Effects = Effects
    self:Save()
end



return SoundState