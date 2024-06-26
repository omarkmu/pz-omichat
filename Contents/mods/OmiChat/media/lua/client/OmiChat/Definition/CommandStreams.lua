---@class omichat.api.client
local OmiChat = require 'OmiChat/API/Client'

local concat = table.concat
local pairs = pairs
local getText = getText
local vanillaCommands = require 'OmiChat/Definition/VanillaCommandList'

local utils = OmiChat.utils
local Option = OmiChat.Option
local StreamInfo = OmiChat.StreamInfo

---Checks whether the current player can use custom admin commands.
---@return boolean
local function canUseAdminCommands()
    local player = getSpecificPlayer(0)
    local access = player and player:getAccessLevel()
    return utils.getNumericAccessLevel(access) >= Option.MinimumCommandAccessLevel
end

---Searches for a known language with loose matching.
---@param input string
---@return string?
local function matchKnownLanguage(input)
    ---@type omichat.SearchContext
    local ctx = {
        terminateOnExact = true,
        searchDisplay = true,
        search = input,
        display = utils.getTranslatedLanguageName,
    }

    local searchResult = OmiChat.searchStrings(ctx, OmiChat.getRoleplayLanguages())
    if searchResult.exact then
        return searchResult.exact.value
    end

    local result = searchResult.results[1]
    if result then
        return result.value
    end
end

---Callback function to display help text for a stream.
---@param info omichat.StreamInfo
local function showHelpText(info)
    OmiChat.addInfoMessage(info:getHelpText())
end

---@type omichat.CommandStream[]
return {
    {
        name = 'name',
        command = '/name ',
        omichat = {
            isCommand = true,
            helpText = 'UI_OmiChat_HelpText_Name',
            isEnabled = function() return Option:isNameCommandEnabled() end,
            onUse = function(ctx)
                if Option:isNameCommandSetNickname() then
                    local _, feedback = OmiChat.setNickname(ctx.text)
                    if feedback then
                        OmiChat.addInfoMessage(feedback)
                    end

                    return
                end

                local input = utils.trim(ctx.text or '')
                if #input == 0 then
                    OmiChat.addInfoMessage(getText('UI_OmiChat_Info_SetNameEmpty'))
                    return
                end

                local _, feedback = OmiChat.updateCharacterName(input, Option:isNameCommandSetFullName())
                if feedback then
                    OmiChat.addInfoMessage(feedback)
                end
            end,
            onHelp = function()
                local msg = 'UI_OmiChat_HelpText_Name'
                if Option:isNameCommandSetFullName() then
                    msg = 'UI_OmiChat_HelpText_NameFull'
                end

                OmiChat.addInfoMessage(getText(msg))
            end,
        },
    },
    {
        name = 'nickname',
        command = '/nickname ',
        omichat = {
            isCommand = true,
            helpText = 'UI_OmiChat_HelpText_Nickname',
            isEnabled = function() return Option:isNicknameCommandEnabled() end,
            onUse = function(ctx)
                local _, feedback = OmiChat.setNickname(ctx.text)
                if feedback then
                    OmiChat.addInfoMessage(feedback)
                end
            end,
        },
    },
    {
        name = 'clearnames',
        command = '/clearnames ',
        omichat = {
            isCommand = true,
            helpText = 'UI_OmiChat_HelpText_ClearNames',
            isEnabled = canUseAdminCommands,
            onUse = function()
                OmiChat.requestClearNames()
            end,
        },
    },
    {
        name = 'setname',
        command = '/setname ',
        omichat = {
            isCommand = true,
            helpText = 'UI_OmiChat_HelpText_SetName',
            suggestSpec = { 'online-username' },
            isEnabled = canUseAdminCommands,
            onUse = function(ctx)
                OmiChat.requestSetName(ctx.text)
            end,
        },
    },
    {
        name = 'iconinfo',
        command = '/iconinfo ',
        omichat = {
            isCommand = true,
            helpText = 'UI_OmiChat_HelpText_IconInfo',
            isEnabled = canUseAdminCommands,
            onUse = function(ctx)
                local command = utils.trim(ctx.text)
                if #command == '' then
                    OmiChat.addInfoMessage(ctx.stream:getHelpText())
                    return
                end

                if getTexture(command) then
                    local image = table.concat { ' <SPACE> <IMAGE:', command, ',15,14> ' }
                    OmiChat.addInfoMessage(getText('UI_OmiChat_Info_Icon', command, image))
                    return
                end

                local textureName = utils.getTextureNameFromIcon(command)
                if not textureName or not getTexture(textureName) then
                    OmiChat.addInfoMessage(getText('UI_OmiChat_Info_IconUnknown', command))
                    return
                end

                local image = table.concat { ' <SPACE> <IMAGE:', textureName, ',15,14> ' }
                OmiChat.addInfoMessage(getText('UI_OmiChat_Info_IconAlias', textureName, image, command))
            end,
        },
    },
    {
        name = 'seticon',
        command = '/seticon ',
        omichat = {
            isCommand = true,
            helpText = 'UI_OmiChat_HelpText_SetIcon',
            suggestSpec = { 'online-username-with-self' },
            isEnabled = canUseAdminCommands,
            onUse = function(ctx)
                if not OmiChat.requestSetIcon(ctx.text) then
                    local args = utils.parseCommandArgs(ctx.text)
                    local icon = args[2]
                    if not args[1] or not icon then
                        OmiChat.addInfoMessage(ctx.stream:getHelpText())
                    else
                        OmiChat.addInfoMessage(getText('UI_OmiChat_Info_IconUnknown', icon))
                    end
                end
            end,
        },
    },
    {
        name = 'resetname',
        command = '/resetname ',
        omichat = {
            isCommand = true,
            helpText = 'UI_OmiChat_HelpText_ResetName',
            suggestSpec = { 'online-username' },
            isEnabled = canUseAdminCommands,
            onUse = function(ctx)
                OmiChat.requestResetName(ctx.text)
            end,
        },
    },
    {
        name = 'reseticon',
        command = '/reseticon ',
        omichat = {
            isCommand = true,
            helpText = 'UI_OmiChat_HelpText_ResetIcon',
            suggestSpec = { 'online-username-with-self' },
            isEnabled = canUseAdminCommands,
            onUse = function(ctx)
                OmiChat.requestResetIcon(ctx.text)
            end,
        },
    },
    {
        name = 'addlanguage',
        command = '/addlanguage ',
        omichat = {
            isCommand = true,
            helpText = 'UI_OmiChat_HelpText_AddLanguage',
            suggestSpec = {
                'online-username-with-self',
                {
                    type = 'language',
                    ---@param result string
                    ---@param args string[]
                    ---@return boolean
                    filter = function(result, args)
                        local username = args[1]
                        if not username then
                            return true
                        end

                        -- don't suggest adding already known languages
                        return not OmiChat.checkPlayerKnowsLanguage(username, result)
                    end,
                },
            },
            isEnabled = canUseAdminCommands,
            onUse = function(ctx)
                OmiChat.requestAddLanguage(ctx.text)
            end,
        },
    },
    {
        name = 'resetlanguages',
        command = '/resetlanguages ',
        omichat = {
            isCommand = true,
            helpText = 'UI_OmiChat_HelpText_ResetLanguages',
            suggestSpec = { 'online-username-with-self' },
            isEnabled = canUseAdminCommands,
            onUse = function(ctx)
                OmiChat.requestResetLanguages(ctx.text)
            end,
        },
    },
    {
        name = 'setlanguageslots',
        command = '/setlanguageslots ',
        omichat = {
            isCommand = true,
            helpText = 'UI_OmiChat_HelpText_SetLanguageSlots',
            suggestSpec = { 'online-username-with-self' },
            isEnabled = canUseAdminCommands,
            onUse = function(ctx)
                OmiChat.requestSetLanguageSlots(ctx.text)
            end,
        },
    },
    {
        name = 'card',
        command = '/card ',
        omichat = {
            isCommand = true,
            helpText = 'UI_ServerOptionDesc_Card',
            onUseDisabled = showHelpText,
            onUse = function(ctx)
                if not OmiChat.requestDrawCard() then
                    OmiChat.addInfoMessage(ctx.stream:getHelpText())
                end
            end,
            isEnabled = function()
                local player = getSpecificPlayer(0)
                if not player then
                    return false
                end

                return player:getAccessLevel() ~= 'None' or utils.hasAnyItemType(player, Option:getCardItems())
            end,
        },
    },
    {
        name = 'flip',
        command = '/flip ',
        omichat = {
            isCommand = true,
            helpText = 'UI_OmiChat_HelpText_Flip',
            onUseDisabled = showHelpText,
            onUse = function(ctx)
                if not OmiChat.requestFlipCoin() then
                    OmiChat.addInfoMessage(ctx.stream:getHelpText())
                end
            end,
            isEnabled = function()
                local player = getSpecificPlayer(0)
                if not player then
                    return false
                end

                return player:getAccessLevel() ~= 'None' or utils.hasAnyItemType(player, Option:getCoinItems())
            end,
        },
    },
    {
        name = 'roll',
        command = '/roll ',
        omichat = {
            isCommand = true,
            helpText = 'UI_ServerOptionDesc_Roll',
            onUseDisabled = showHelpText,
            onUse = function(ctx)
                local command = utils.trim(ctx.text)
                local first = command:split(' ')[1]
                local sides = first and tonumber(first)
                if not sides and #command == 0 then
                    sides = 6
                elseif not sides then
                    OmiChat.addInfoMessage(ctx.stream:getHelpText())
                    return
                end

                if not OmiChat.requestRollDice(sides) then
                    OmiChat.addInfoMessage(ctx.stream:getHelpText())
                end
            end,
            isEnabled = function()
                local player = getSpecificPlayer(0)
                if not player then
                    return false
                end

                return player:getAccessLevel() ~= 'None' or utils.hasAnyItemType(player, Option:getDiceItems())
            end,
        },
    },
    {
        name = 'emotes',
        command = '/emotes ',
        omichat = {
            isCommand = true,
            helpText = 'UI_OmiChat_HelpText_Emotes',
            isEnabled = function() return Option.EnableEmotes end,
            onUse = function(ctx) ctx.stream:onHelp() end,
            onHelp = function()
                -- collect currently available emotes
                local emotes = {}
                for k in pairs(OmiChat._emotes) do
                    emotes[#emotes + 1] = k
                end

                if #emotes == 0 then
                    -- no emotes; ignore
                    return
                end

                table.sort(emotes)

                local parts = {
                    getText('UI_OmiChat_Info_AvailableEmotes'),
                }

                for i = 1, #emotes do
                    parts[#parts + 1] = ' <LINE> * .'
                    parts[#parts + 1] = emotes[i]
                end

                OmiChat.addInfoMessage(concat(parts))
            end,
        },
    },
    {
        name = 'language',
        command = '/language ',
        shortCommand = '/lang ',
        omichat = {
            isCommand = true,
            helpText = 'UI_OmiChat_HelpText_SwitchLanguage',
            suggestSpec = { 'known-language' },
            isEnabled = function() return #OmiChat.getRoleplayLanguages() > 1 end,
            onUse = function(ctx)
                local args = utils.parseCommandArgs(ctx.text)
                local command = args[1]
                if not command then
                    OmiChat.addInfoMessage(getText('UI_OmiChat_HelpText_SwitchLanguage'))
                    return
                end

                local lang = matchKnownLanguage(command)
                if not lang or not OmiChat.setCurrentRoleplayLanguage(lang) then
                    OmiChat.addInfoMessage(getText('UI_OmiChat_Error_SwitchUnknownLanguage', command))
                    return
                end

                lang = utils.getTranslatedLanguageName(lang)
                OmiChat.addInfoMessage(getText('UI_OmiChat_Success_SwitchLanguage', lang))
            end,
        },
    },
    {
        -- reimplementing this because the vanilla clear doesn't actually clear the chatbox
        name = 'clear',
        command = '/clear ',
        omichat = {
            isCommand = true,
            isEnabled = function() return isAdmin() or isCoopHost() end,
            onUse = function()
                OmiChat.clearMessages()
                OmiChat.addInfoMessage(getText('UI_OmiChat_Info_Clear'))
            end,
        },
    },
    {
        name = 'help',
        command = '/help ',
        omichat = {
            isCommand = true,
            onUse = function(ctx)
                local accessLevel = utils.getEffectiveAccessLevel()
                local command = ctx.text
                if not accessLevel then
                    -- something went wrong, defer to default help command
                    SendCommandToServer('/help ' .. command)
                    return
                end

                command = utils.trim(command)

                -- specific command help
                if #command > 0 then
                    ---@type omichat.StreamInfo?, function?, string?
                    local helpStream, helpCallback, helpText

                    for i = 1, #OmiChat._commandStreams do
                        local stream = StreamInfo:new(OmiChat._commandStreams[i])
                        if stream:getName() == command and stream:isEnabled() then
                            helpCallback = stream:getHelpCallback()
                            helpText = stream:getHelpTextStringID() and stream:getHelpText()
                            if helpCallback or helpText then
                                helpStream = stream
                                break
                            end
                        end
                    end

                    if helpCallback then
                        helpCallback(helpStream)
                    elseif helpText then
                        OmiChat.addInfoMessage(helpText)
                    else
                        -- defer to default help command
                        SendCommandToServer('/help ' .. command)
                    end

                    return
                end

                -- overall help
                local seen = {}
                local commands = {} ---@type omichat.VanillaCommand[]

                for i = 1, #OmiChat._commandStreams do
                    local stream = StreamInfo:new(OmiChat._commandStreams[i])
                    if stream:config() then
                        local name = stream:getName()
                        local helpText = stream:getHelpTextStringID()
                        if not seen[name] and helpText and stream:isEnabled() then
                            seen[name] = true
                            commands[#commands + 1] = { name = name, helpText = helpText, access = 0 }
                        end
                    end
                end

                for i = 1, #vanillaCommands do
                    local info = vanillaCommands[i]
                    if info.name and info.helpText and not seen[info.name] then
                        if utils.hasAccess(info.access, accessLevel) then
                            commands[#commands + 1] = info
                        end
                    end
                end

                table.sort(commands, function(a, b) return a.name < b.name end)

                local result = { getText('UI_OmiChat_Info_CommandList') }
                for i = 1, #commands do
                    local cmd = commands[i]
                    result[#result + 1] = ' <LINE> * '
                    result[#result + 1] = cmd.name
                    result[#result + 1] = ' : '

                    if cmd.helpTextArgs then
                        result[#result + 1] = getText(cmd.helpText, unpack(cmd.helpTextArgs))
                    else
                        result[#result + 1] = getText(cmd.helpText)
                    end
                end

                OmiChat.addInfoMessage(concat(result))
            end,
        },
    },
}
