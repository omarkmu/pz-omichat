---Schema class for mod configuration.

local utils = require 'OmiChat/utils'
local defaultStreamData = require 'OmiChat/Definition/DefaultStreamData'
local schema = utils.schema


---@class omichat.ConfigurationSchema : omi.Schema
local ConfigurationSchema = schema.Schema:derive()


---Returns a list of default language objects.
---@return omichat.Configuration.LanguageDefinition[]
function ConfigurationSchema:getDefaultLanguages()
    return {
        { Name = 'English' },
        { Name = 'French' },
        { Name = 'Italian' },
        { Name = 'German' },
        { Name = 'Spanish' },
        { Name = 'Danish' },
        { Name = 'Dutch' },
        { Name = 'Hungarian' },
        { Name = 'Norwegian' },
        { Name = 'Polish' },
        { Name = 'Portuguese' },
        { Name = 'Russian' },
        { Name = 'Turkish' },
        { Name = 'Japanese' },
        { Name = 'Mandarin' },
        { Name = 'Finnish' },
        { Name = 'Korean' },
        { Name = 'Thai' },
        { Name = 'Ukrainian' },
        { Name = 'ASL', Signed = true },
    }
end

---Returns a list of default stream configuration objects, without default data.
---@return omichat.Configuration.StreamDefinition[]
function ConfigurationSchema:getDefaultStreams()
    return {
        { Stream = 'admin', Enable = true },
        { Stream = 'say', Enable = true },
        { Stream = 'yell', Enable = true },
        { Stream = 'low', Enable = true },
        { Stream = 'whisper', Enable = true },
        { Stream = 'me', Enable = true },
        { Stream = 'meloud', Enable = true },
        { Stream = 'mequiet', Enable = true },
        { Stream = 'mewhisper', Enable = false },
        { Stream = 'do', Enable = true },
        { Stream = 'doloud', Enable = true },
        { Stream = 'doquiet', Enable = true },
        { Stream = 'dowhisper', Enable = false },
        { Stream = 'ooc', Enable = true },
        { Stream = 'private', Enable = true },
        { Stream = 'faction', Enable = true },
        { Stream = 'safehouse', Enable = true },
        { Stream = 'general', Enable = true },
    }
end

---Gets the chat type associated with a built-in stream.
---@param stream string
---@return omichat.ChatTypeString?
function ConfigurationSchema:getStreamChatType(stream)
    if not stream then
        return
    end

    local data = defaultStreamData[stream]
    return data and data.ChatType
end

---Gets the command type associated with a built-in stream.
---@param stream string
---@return string?
function ConfigurationSchema:getStreamCommandType(stream)
    if not stream then
        return
    end

    local data = defaultStreamData[stream]
    return data and data.CommandType
end

---Transforms configured streams to include required data and fix incompatible fields.
---@param streams omichat.Configuration.StreamDefinition[]
---@return omichat.Configuration.StreamDefinition[]
function ConfigurationSchema:processStreams(streams)
    local seen = { [''] = true }
    local processed = {}

    for i = 1, #streams do
        local stream = streams[i]
        local streamType = utils.trim(stream.Stream or '')
        local streamName = utils.trim(stream.Name or '')
        local isCustom = streamType == '' or streamType == 'custom'

        local compareKey = isCustom and streamName or streamType
        if not seen[compareKey] then
            seen[compareKey] = true
            local data = defaultStreamData[streamType]
            if not data then
                data = {}
                if not isCustom then
                    utils.log.error('Missing defaults for built-in stream `%s`', tostring(streamType))
                end
            end

            for k, v in pairs(data) do
                local vType = type(v)
                if not isCustom and (k == 'ChatType' or k == 'CommandType') then
                    -- always copy these keys for built-in streams
                    stream[k] = v
                elseif type(stream[k]) ~= vType then
                    -- use defaults for invalid values
                    stream[k] = vType == 'table' and utils.copy(v) or v
                end
            end

            if isCustom then
                stream.Stream = 'custom'
                stream.Name = streamName
                stream.ChatType = utils.isNilOrWhitespace(stream.ChatType) and 'say' or stream.ChatType
                stream.CommandType = utils.isNilOrWhitespace(stream.CommandType) and 'chat' or stream.CommandType
            else
                stream.Stream = streamType
                stream.Name = nil
            end

            local isValidBuiltin = stream.Stream ~= 'custom' and not utils.isNilOrWhitespace(stream.Stream)
            local isValidCustom = stream.Stream == 'custom' and not utils.isNilOrWhitespace(stream.Name)
            if isValidBuiltin or isValidCustom then
                processed[#processed + 1] = stream
            end
        end
    end

    return processed
end


---@param options omi.Args.Schema
---@return omichat.ConfigurationSchema
function ConfigurationSchema:new(options)
    local this = schema.Schema.new(self, options) ---@cast this omichat.ConfigurationSchema
    return this
end

return ConfigurationSchema
