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
    Id: number | string,
    Length: number,
    Properties: {[string]: any}?,
    Effects: {[string]: {[string]: any}}?,
    Events: {SoundDataEntryEvent}?,
    [string]: SoundDataEntry,
}

--Classes
export type SoundState = {
    Save: (SoundState) -> (),
    Play: (SoundState) -> (),
    Resume: (SoundState) -> (),
    Pause: (SoundState) -> (),
    Stop: (SoundState) -> (),
    SetEffects: (SoundState, {[string]: {[string]: any}}) -> (),
    StateValue: StringValue,
}

export type ClientSound = {
    Update: (ClientSound) -> (),
}



return {}