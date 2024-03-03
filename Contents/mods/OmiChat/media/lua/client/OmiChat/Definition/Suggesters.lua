local vanillaCommands = require 'OmiChat/Definition/VanillaCommandList'

local concat = table.concat
local pairs = pairs
local ISChat = ISChat ---@cast ISChat omichat.ISChat

---@class omichat.api.client
local OmiChat = require 'OmiChat/API/Client'
local utils = OmiChat.utils
local StreamInfo = OmiChat.StreamInfo

---@class omichat.suggester.StreamResult
---@field command string
---@field full string?

---Collects results from a list of streams into `startsWith` and `contains`.
---@param tab (omichat.ChatStream | omichat.CommandStream)[]
---@param command string
---@param fullCommand string
---@param currentTabID integer
---@param startsWith omichat.suggester.StreamResult[]
---@param contains omichat.suggester.StreamResult[]
local function collectStreamResults(tab, command, fullCommand, currentTabID, startsWith, contains)
    for i = 1, #tab do
        local stream = StreamInfo:new(tab[i])
        if stream:isTabID(currentTabID) and stream:isEnabled() then
            local streamCommand = stream:getCommand()
            local shortCommand = stream:getShortCommand()

            local checkAliases = false
            if utils.startsWith(streamCommand, fullCommand) then
                startsWith[#startsWith + 1] = { command = streamCommand }
            elseif shortCommand and utils.startsWith(shortCommand, fullCommand) then
                startsWith[#startsWith + 1] = { command = shortCommand, full = streamCommand }
            elseif utils.contains(streamCommand, command) then
                contains[#contains + 1] = { command = streamCommand }
            elseif shortCommand and utils.contains(shortCommand, command) then
                contains[#contains + 1] = { command = shortCommand, full = streamCommand }
            else
                checkAliases = true
            end

            if checkAliases then
                for alias in stream:aliases() do
                    if utils.startsWith(alias, fullCommand) then
                        startsWith[#startsWith + 1] = { command = alias, full = streamCommand }
                        break
                    elseif utils.contains(alias, command) then
                        contains[#contains + 1] = { command = alias, full = streamCommand }
                        break
                    end
                end
            end
        end
    end
end

---Appends members of `t1` to `t2`.
---@param t1 unknown[]
---@param t2 unknown[]
---@return unknown[]
local function extend(t1, t2)
    for i = 1, #t2 do
        t1[#t1 + 1] = t2[i]
    end

    return t1
end

---@type omichat.Suggester[]
return {
    {
        name = 'commands',
        priority = 15,
        suggest = function(_, info)
            local instance = ISChat.instance
            if not instance then
                return
            end

            local currentTabID = instance.currentTabID
            if OmiChat.chatCommandToStream(info.input) then
                return
            end

            local player = getSpecificPlayer(0)
            local accessLevel = player and player:getAccessLevel()

            if isCoopHost() then
                accessLevel = 'admin'
            end

            if not accessLevel then
                return
            end

            local command = info.input:match('^/(%S+)$')
            if not command then
                return
            end

            command = command:lower()
            local fullCommand = '/' .. command

            local startsWith = {}
            local contains = {}

            -- chat & command streams
            collectStreamResults(ISChat.allChatStreams, command, fullCommand, currentTabID, startsWith, contains)
            collectStreamResults(OmiChat._commandStreams, command, fullCommand, currentTabID, startsWith, contains)

            -- vanilla command streams
            for i = 1, #vanillaCommands do
                local commandInfo = vanillaCommands[i]
                if utils.hasAccess(commandInfo.access, accessLevel) then
                    local vanillaCommand = concat { '/', commandInfo.name, ' ' }
                    if utils.startsWith(vanillaCommand, fullCommand) then
                        startsWith[#startsWith + 1] = { command = vanillaCommand }
                    elseif utils.contains(vanillaCommand, command) then
                        contains[#contains + 1] = { command = vanillaCommand }
                    end
                end
            end

            local seen = {}

            ---@type omichat.suggester.StreamResult[]
            local results = extend(startsWith, contains)
            for i = 1, #results do
                local result = results[i]
                local display = result.command
                if result.full then
                    display = concat { result.command, ' [', utils.trimright(result.full), ']' }
                end

                if not seen[result.command] then
                    info.suggestions[#info.suggestions + 1] = {
                        type = 'command',
                        display = display,
                        suggestion = result.command,
                    }

                    seen[result] = true
                end
            end
        end,
    },
    {
        name = 'online-usernames',
        priority = 10,
        suggest = function(_, info)
            if #info.input < 2 then
                return
            end

            local stream = OmiChat.chatCommandToStream(info.input)
            local wantsSuggestions = stream and stream:suggestUsernames()

            local player = getSpecificPlayer(0)
            local isCommand = not stream and info.input:sub(1, 1) == '/' and player and player:getAccessLevel() ~= 'None'

            if not wantsSuggestions and not isCommand then
                return
            end

            local onlinePlayers = getOnlinePlayers()
            local parts = luautils.split(info.input, ' ')
            if #parts == 0 or (isCommand and #parts == 1) then
                return
            end

            local startsWith = {}
            local contains = {}

            local ownUsername = player and player:getUsername()
            local includeSelf = utils.default(stream and stream:suggestOwnUsername(), true)
            local last = parts[#parts]:lower()
            for i = 0, onlinePlayers:size() - 1 do
                local onlinePlayer = onlinePlayers:get(i)
                local username = onlinePlayer and onlinePlayer:getUsername()

                if includeSelf or username ~= ownUsername then
                    local usernameLower = username and username:lower()
                    if #parts == 1 then
                        -- only command specified; include all options
                        contains[#contains + 1] = username
                    elseif usernameLower == last then
                        -- exact match
                        return
                    elseif usernameLower and utils.startsWith(usernameLower, last) then
                        startsWith[#startsWith + 1] = username
                    elseif usernameLower and utils.contains(usernameLower, last) then
                        contains[#contains + 1] = username
                    end
                end
            end

            local prefix = concat(parts, ' ', 1, #parts == 1 and 1 or #parts - 1)
            local results = extend(startsWith, contains)
            for i = 1, #results do
                local username = results[i]
                if utils.contains(username, ' ') then
                    username = concat({ '"', username:gsub('"', '\\"'), '"' })
                end

                info.suggestions[#info.suggestions + 1] = {
                    type = 'user',
                    display = username,
                    suggestion = concat({ prefix, username }, ' ') .. ' ',
                }
            end
        end,
    },
    {
        name = 'emotes',
        priority = 5,
        suggest = function(_, info)
            local instance = ISChat.instance
            if not instance then
                return
            end

            local currentTabID = instance.currentTabID
            local stream = OmiChat.chatCommandToStream(info.input)
            if not stream then
                if utils.startsWith(info.input, '/') then
                    -- disallow for unknown commands
                    return
                end

                local default = OmiChat.getDefaultTabStream(currentTabID)
                if not default then
                    return
                end

                stream = default
            end

            if not stream:isTabID(currentTabID) then
                return
            end

            if not stream:isEnabled() or not stream:isAllowEmotes() then
                return
            end

            local existingEmote = OmiChat.getEmoteFromCommand(info.input)
            if existingEmote then
                return
            end

            local start, _, whitespace, period, text = info.input:find('(%s*)()%.([%w_]*)$')

            -- require whitespace unless the emote is at the start
            if not start or (start ~= 1 and #whitespace == 0) then
                return
            end

            text = text:lower()
            local startsWith = {}
            local contains = {}

            for k in pairs(OmiChat._emotes) do
                if k:lower() == text then
                    -- exact match
                    return
                elseif utils.startsWith(k, text) then
                    startsWith[#startsWith + 1] = k
                elseif utils.contains(k, text) then
                    contains[#contains + 1] = k
                end
            end

            local prefix = info.input:sub(1, period)
            local results = extend(startsWith, contains)
            for i = 1, #results do
                local emote = results[i]
                info.suggestions[#info.suggestions + 1] = {
                    type = 'emote',
                    display = '.' .. emote,
                    suggestion = concat({ prefix, emote }),
                }
            end
        end,
    },
}
