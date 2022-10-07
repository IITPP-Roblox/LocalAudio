--[[
TheNexusAvenger

Audio for the test demo.
--]]

return {
    MaxConcurrentTracks = {
        ["Demo.Local"] = 1,
    },
    Sounds = {
        Demo = {
            Local = {
                Id = 12222253,
                Length = 1.207,
                Events = {
                    {
                        Time = 0,
                        Name = "CheerStart",
                    },
                    {
                        Time = 0.2,
                        Name = "CheerSecond",
                    },
                },
            },
            LocalLooped = {
                Id = 12222253,
                Length = 1.207,
                Events = {
                    {
                        Time = 0,
                        Name = "CheerStart",
                    },
                    {
                        Time = 0.2,
                        Name = "CheerSecond",
                    },
                },
                Properties = {
                    Volume = 0.2,
                    Looped = true,
                },
            },
            Global = {
                Id = 12221967,
                Length = 0.293,
                Properties = {
                    Volume = 0.2,
                },
            },
        },
    },
}