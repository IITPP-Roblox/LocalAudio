--[[
TheNexusAvenger

Returns the audio data for the game.
For now, it is hard-coded to the location the Innovation Inc Thermal
Power Plant uses. Pull requests are open to allow other options.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalAudioTypes = require(script.Parent:WaitForChild("LocalAudioTypes"))

return require(ReplicatedStorage:WaitForChild("Data"):WaitForChild("Audio")) :: LocalAudioTypes.SoundData