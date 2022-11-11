--[[
TheNexusAvenger

Types used with the LocalAudio module.
--]]

--Data
export type SoundData = {
    MaxConcurrentTracks: {[string]: number}?,
    Sounds: {[string]: SoundDataEntry},
}

export type SoundDataEntryEvent = {
    Time: number,
    Name: string,
    [string]: any,
}

export type SoundDataEntry = {
    Id: number,
    Length: number,
    Properties: {[string]: any}?,
    Effects: {[string]: {[string]: any}}?,
    Events: {SoundDataEntryEvent}?,
    [string]: SoundDataEntry,
}

--Classes
export type SoundState = {
    Save: (SoundState) -> nil,
    Play: (SoundState) -> nil,
    Resume: (SoundState) -> nil,
    Pause: (SoundState) -> nil,
    Stop: (SoundState) -> nil,
    SetEffects: (SoundState, {[string]: {[string]: any}}) -> nil,
    StateValue: StringValue,
}

export type ClientSound = {
    Update: (ClientSound) -> nil,
}



return {}