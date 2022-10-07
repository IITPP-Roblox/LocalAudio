# LocalAudio
LocalAudio is a module developed for the [Innovation Inc Thermal Power Plant on Roblox](https://www.roblox.com/games/2337178805/Innovation-Inc-Thermal-Power-Plant)
to handle audios played on the client. This was primarily
developed to reduce memory usage of audios that aren't
being used since they are stored in memory.

Instead of audios being stored as instances, audio is
stored as data and given readable names instead of ids
to reduce replacing audio ids when there are duplicates.
Audio instances are created when needed on the client
and are synchronized if a user joins after the audio
starts. Most functionality with Roblox audio, including
pausing and resuming audio, is supported. However,
features like changing the volume after playing is
not supported.

# Setup
## Project
This project uses [Rojo](https://github.com/rojo-rbx/rojo) for the project
structure. Two project files in included in the repository.
* `default.project.json` - Structure for just the module. Intended for use
  with `rojo build` and to be included in Rojo project structures as a
  dependency.
* `demo.project.json` - Full Roblox place that can be synced into Roblox
  studio and ran with demo models.

## Game
### Loading Setup
LocalAudio is not self-contained and requires additional setup to use.
On the server, the module only needs to be `require`d. On the client,
it needs to be `require`d **and** `SetUp()` needs to be invoked.
[LocalAudioSetup.client.lua](src/../demo/StarterPlayerScripts/LocalAudioSetup.client.lua)
is an example if LocalAudio is directly under `ReplicatedStorage`.

```lua
require(game:GetService("ReplicatedStorage"):WaitForChild("LocalAudio")):SetUp()
```

The specific location of LocalTween does not matter as long as `SetUp`
is called on the client.

### Data Setup
Unlike the loading, the data is currently hard-coded to be in a `ModuleScript`
named `Audio` in an Instance of any time named `Data` under `ReplicatedStorage`.
More flexible options are open for consideration using a pull request with
changes to [AudioData.lua](src/AudioData.lua).

Audio names are set up as a tree structure grouped by relevance. For example, a
car with a tire sound, a horn sound, a turn signal sound, could be given the names
of `Car.External.Tire`, `Car.External.Horn`, and `Car.TurnSignal`. The root of this
tree of sounds is a table with up to 2 entries:
- `Sounds` - The tree structure of the sounds covered below.
- `MaxConcurrentTracks` (Optional) - The maximum amount of a track name or group that
  can play.
  - The values inside are a key-value pair with the key being the name of the group to
    apply to and the value being the maximum total sounds (>=1). Using the example ids
    from above, if you wanted only 1 horn to be active, set `["Car.External.Horn"] = 1`.
    In order to group sounds, the common group name would be used, like `["Car.External"] = 1`
    or `["Car"] = 1`. Combinations of different groups and regular expressions aren't
    supported features.

`Sounds` is a dictionary where they keys are name of the sound or group and the
values are internally called `SoundDataEntry`s. An entry can contain the information
for a sound, act as a grouping of sounds, or both. A `SoundDataEntry` can have the
following properties if it is storing an audio:
- `Id`: Number id (no `rbxassetid://`) of the sound.
- `Length`: Length of the sound in seconds without modifiers like `PlaybackSpeed`.
- `Properties` (Optional): Dictionary where the keys are the names of the properties
  of the audio and the values are the values to set. `PlaybackSpeed`, `Looped`, and
  `TimePosition` are supported.
- `Effects` (Optional): Dictionary where thee keys are the types of the `SoundEffect`
  and the values are dictionaries of property names and values for the sound effects.

The following is an example of the data:
```lua
{
    MaxConcurrentTracks = { --This is optional. If missing, no limits are enforced.
        ["Test1"] = 2, --Any audio that starts with "Test1", like "Test1.Test2" and "Test1.Test3", will only have up to 2 active sounds.
        ["Test2.Test5"] = 1, --Any audio that starts with "Test2.Test3", like "Test2.Test3" and "Test2.Test3.Test4", will only have up to 1 active sound.
    },
    Sounds = {
        Test1 = { --NOT playable (no id)
            Test2 = { --Playable as "Test1.Test2"
                Id = 1,
                Length = 1,
                --No properties changed
                --No effects
            },
            Test3 = { --Playable as "Test1.Test3"
                Id = 2,
                Length = 1,
                Properties = {
                    Looped = true,
                    TimePosition = 0.5,
                },
                Effects = {
                    CompressorSoundEffect = {
                        GainMakeup = 1.5,
                    },
                    DistortionSoundEffect = {
                        Level = 0.5,
                    },
                },
                Event = { --Events that will fire when a time is reached.
                    {
                        Time = 0,
                        Name = "MyEvent1",
                    },
                    {
                        Time = 0.2,
                        Name = "MyEvent1", --Names don't have to be unique.
                    },
                    {
                        Time = 1,
                        Name = "MyEvent2",
                    },
                    {
                        Time = 1, --Times don't have to be unique.
                        Name = "MyEvent3",
                    },
                },
            },
        },
        Test2 = { --Playable as "Test2"
            Id = 2,
            Length = 1,
            --No properties changed
            --No effects
            Test3 = { --Playable as "Test2.Test3"
                Id = 3,
                Length = 1,
                --No properties changed
                --No effects
                Test4 = { --Playable as "Test2.Test3.Test4"
                    Id = 4,
                    Length = 1,
                    --No properties changed
                    --No effects
                },
            },
        },
        Test5 = { --Playable as "Test5", notice how there is no entry under MaxConcurrentTracks for limits.
            Id = 5,
            Length = 1,
            --No properties changed
            --No effects
        },
    },
}
```

# API
The API intended to be used is made up of static functions that map to the native
Roblox methods, including:
- `LocalAudio.OnEvent: RBXScriptSignal<string, SoundDataEntryEvent, Instance?>` - Event that is fired when a sound has an event.
- `LocalAudio:OnOnEventFired(Name: string): RBXScriptSignal<string, SoundDataEntryEvent, Instance?>` - Returns an event that is fired when an event from a sound of the given name is fired.
- `LocalAudio:PreloadAudio(Id: string): nil` - Preloads an audio.
- `LocalAudio:PlayAudio(Id: string, Parent: Instance?): nil` - Plays an audio.
- `LocalAudio:ResumeAudio(Id: string, Parent: Instance?): nil` - Resumes an audio if one is paused.
- `LocalAudio:PauseAudio(Id: string, Parent: Instance?): nil` - Pauses an audio if one is playing.
- `LocalAudio:StopAudio(Id: string, Parent: Instance?): nil` - Stops an audio if one is playing.
- `LocalAudio:SetEffects(Id: string, Parent: Instance?, Effects: {[string]: {[string]: any}}): nil` -
  Sets the effects for an audio if one is active.
- `LocalAudio:SetUp()` - Sets up the client (see the loading setup instructions).

The parameters for the functions include:
- `Id`: The string id of the audio in the data, such as `"Test1.Test3"`.
- `Parent` (Optional): Parent of the audio to store. If none is specified,
  `SoundService` is used.
- `Effects` (Optional): See the `Effects` property in the data setup.

Playing multiple of a single audio id for multiple parents is supported, but
playing multiple of a single audio id for a single parent is not supported.
Results may be unpredicable.

# License
This project is available under the terms of the MIT License. See [LICENSE](LICENSE)
for details.