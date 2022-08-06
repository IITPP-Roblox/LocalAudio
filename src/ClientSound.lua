--[[
TheNexusAvenger

Instance of a sound on the client.
--]]

local Workspace = game:GetService("Workspace")
local SoundService = game:GetService("SoundService")
local HttpService = game:GetService("HttpService")

local AudioData = require(script.Parent:WaitForChild("AudioData"))
local LocalAudioTypes = require(script.Parent:WaitForChild("LocalAudioTypes"))

local ClientSound = {}
ClientSound.InitialTimePositionIgnore = 0.5
ClientSound.__index = ClientSound



--[[
Creates the client sound.
--]]
function ClientSound.new(Id: string, ReplicationValue: StringValue, Parent: Instance?): LocalAudioTypes.ClientSound
    --Create the object.
    local self = {
        ReplicationValue = ReplicationValue,
    }
    setmetatable(self, ClientSound)

    --Get the sound data.
    local SoundData = AudioData.Sounds
    for _, Tag in pairs(string.split(Id, ".")) do
        SoundData = SoundData[Tag]
        if SoundData == nil then
            error("Sound not found: "..Id.." at part "..Tag)
        end
    end
    self.SoundData = SoundData

    --Create the sound.
    local Sound = Instance.new("Sound")
    Sound.Name = string.gsub(Id, "%.", "")
    Sound.SoundId = "rbxassetid://"..tostring(SoundData.Id)
    for Key, Value in pairs(SoundData.Properties or {}) do
        Sound[Key] = Value
    end
    Sound.Parent = Parent or SoundService
    self.Sound = Sound

    --Connect the value changing.
    ReplicationValue.Changed:Connect(function()
        self:Update()
    end)
    self:Update()

    --Connect the value being destroyed (stopped).
    ReplicationValue:GetPropertyChangedSignal("Parent"):Connect(function()
        if ReplicationValue.Parent then return end
        self.Sound:Stop()
        self.Sound:Destroy()
    end)

    --Return the object.
    return self
end

--[[
Updates the sound based on the latest value.
--]]
function ClientSound:Update()
    --Read the replication data.
    local ReplicationData = HttpService:JSONDecode(self.ReplicationValue.Value)

    --Update the effects.
    local Effects = ReplicationData.Effects or {}
    for _, ExistingEffect in pairs(self.Sound:GetChildren()) do
        if Effects[ExistingEffect.ClassName] then continue end
        ExistingEffect:Destroy()
    end
    for EffectType, EffectData in pairs(Effects) do
        local ExistingEffect = self.Sound:FindFirstChildOfClass(EffectType)
        if not ExistingEffect then
            ExistingEffect = Instance.new(EffectType)
        end
        for Key, Value in pairs(EffectData) do
            ExistingEffect[Key] = Value
        end
        ExistingEffect.Parent = self.Sound
    end

    --Update the sound state.
    if ReplicationData.State == "Play" and not self.Sound.Playing then
        --Determine the time position.
        --The time position is ignored if the sound was just started and is not looped.
        local TimePosition = Workspace:GetServerTimeNow() - ReplicationData.StartTime
        if TimePosition < self.InitialTimePositionIgnore then
            TimePosition = 0
        end
        if self.Sound.Looped then
            TimePosition = TimePosition % self.SoundData.Length
        end

        --Play the sound if the audio is still going.
        if TimePosition > self.SoundData.Length then return end
        self.Sound.TimePosition = TimePosition
        self.Sound:Play()
    elseif ReplicationData.State == "Stop" and self.Sound.Playing then
        self.Sound:Stop()
    end
end



return ClientSound