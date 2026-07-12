---List of default stream configuration objects without default data.
---@namespace omichat

---@type Configuration.StreamDefinition[]
local DefaultStreamList = {
    { Stream = 'admin', Enable = true },
    { Stream = 'say', Enable = true },
    { Stream = 'yell', Enable = true },
    { Stream = 'low', Enable = true },
    { Stream = 'whisper', Enable = true },
    { Stream = 'me', Enable = true },
    { Stream = 'meloud', Enable = true },
    { Stream = 'mequiet', Enable = true },
    { Stream = 'mewhisper', Enable = true },
    { Stream = 'do', Enable = true },
    { Stream = 'doloud', Enable = true },
    { Stream = 'doquiet', Enable = true },
    { Stream = 'dowhisper', Enable = true },
    { Stream = 'ooc', Enable = true },
    { Stream = 'private', Enable = true },
    { Stream = 'faction', Enable = true },
    { Stream = 'safehouse', Enable = true },
    { Stream = 'general', Enable = true },
    { Stream = 'narrate', Enable = true },
}

return DefaultStreamList
