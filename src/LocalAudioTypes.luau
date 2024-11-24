--Types used with the LocalAudio module.
--!strict

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
    Tags: {string}?,
    Events: {SoundDataEntryEvent}?,
    [string]: SoundDataEntry,
}

export type SoundData = SoundDataEntry & {
    MaxConcurrentTracks: {[string]: number}?,
}

return {}