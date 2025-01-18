---@class omichat.api.client
local API = require 'OmiChat/API/Client/Core'

local concat = table.concat
local pairs = pairs
local getText = getText
local vanillaCommands = require 'OmiChat/Definition/VanillaCommandList'

local utils = API.utils
local config = API.Configuration
local CommandStream = API.CommandStream


---Checks whether the current player can use custom admin commands.
---@return boolean
local function canUseAdminCommands()
    local player = getSpecificPlayer(0)
    local access = player and player:getAccessLevel()
    return utils.getNumericAccessLevel(access) >= config.General.MinimumCommandAccessLevel
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

    local searchResult = API.searchStrings(ctx, API.getRoleplayLanguages())
    if searchResult.exact then
        return searchResult.exact.value
    end

    local result = searchResult.results[1]
    if result then
        return result.value
    end
end


---@type omichat.CommandStream[]
return {
    API._cardCommand,
    API._flipCommand,
    API._rollCommand,
    CommandStream:new {
        name = 'name',
        command = '/name ',
        helpTextID = 'UI_OmiChat_HelpText_Name',
        isEnabled = function() return config:isNameCommandEnabled() end,
        onUse = function(ctx)
            if config:isNameCommandSetNickname() then
                local _, feedback = API.setNickname(ctx.text)
                if feedback then
                    API.addInfoMessage(feedback)
                end

                return
            end

            local input = utils.trim(ctx.text or '')
            if #input == 0 then
                API.addInfoMessage(getText('UI_OmiChat_Info_SetNameEmpty'))
                return
            end

            local _, feedback = API.updateCharacterName(input, config:isNameCommandSetFullName())
            if feedback then
                API.addInfoMessage(feedback)
            end
        end,
        onHelp = function()
            local msg = 'UI_OmiChat_HelpText_Name'
            if config:isNameCommandSetFullName() then
                msg = 'UI_OmiChat_HelpText_NameFull'
            end

            API.addInfoMessage(getText(msg))
        end,
    },
    CommandStream:new {
        name = 'nickname',
        command = '/nickname ',
        helpTextID = 'UI_OmiChat_HelpText_Nickname',
        isEnabled = function() return config:isNicknameCommandEnabled() end,
        onUse = function(ctx)
            local _, feedback = API.setNickname(ctx.text)
            if feedback then
                API.addInfoMessage(feedback)
            end
        end,
    },
    CommandStream:new {
        name = 'clearnames',
        command = '/clearnames ',
        helpTextID = 'UI_OmiChat_HelpText_ClearNames',
        isEnabled = canUseAdminCommands,
        onUse = function() API.requestClearNames() end,
    },
    CommandStream:new {
        name = 'setname',
        command = '/setname ',
        helpTextID = 'UI_OmiChat_HelpText_SetName',
        suggestSpec = { 'online-username' },
        isEnabled = canUseAdminCommands,
        onUse = function(ctx) API.requestSetName(ctx.text) end,
    },
    CommandStream:new {
        name = 'iconinfo',
        command = '/iconinfo ',
        helpTextID = 'UI_OmiChat_HelpText_IconInfo',
        isEnabled = canUseAdminCommands,
        onUse = function(ctx)
            local command = utils.trim(ctx.text)
            if #command == 0 then
                ctx.stream:showHelpText()
                return
            end

            if getTexture(command) then
                local image = ' <SPACE> <IMAGE:' .. command .. ',15,14> '
                API.addInfoMessage(getText('UI_OmiChat_Info_Icon', command, image))
                return
            end

            local textureName = utils.getTextureNameFromIcon(command)
            if not textureName or not getTexture(textureName) then
                API.addInfoMessage(getText('UI_OmiChat_Info_IconUnknown', command))
                return
            end

            local image = ' <SPACE> <IMAGE:' .. textureName .. ',15,14> '
            API.addInfoMessage(getText('UI_OmiChat_Info_IconAlias', textureName, image, command))
        end,
    },
    CommandStream:new {
        name = 'seticon',
        command = '/seticon ',
        helpTextID = 'UI_OmiChat_HelpText_SetIcon',
        suggestSpec = { 'online-username-with-self' },
        isEnabled = canUseAdminCommands,
        onUse = function(ctx)
            if not API.requestSetIcon(ctx.text) then
                local args = utils.parseCommandArgs(ctx.text)
                local icon = args[2]
                if not args[1] or not icon then
                    ctx.stream:showHelpText()
                else
                    API.addInfoMessage(getText('UI_OmiChat_Info_IconUnknown', icon))
                end
            end
        end,
    },
    CommandStream:new {
        name = 'resetname',
        command = '/resetname ',
        helpTextID = 'UI_OmiChat_HelpText_ResetName',
        suggestSpec = { 'online-username' },
        isEnabled = canUseAdminCommands,
        onUse = function(ctx)
            API.requestResetName(ctx.text)
        end,
    },
    CommandStream:new {
        name = 'reseticon',
        command = '/reseticon ',
        helpTextID = 'UI_OmiChat_HelpText_ResetIcon',
        suggestSpec = { 'online-username-with-self' },
        isEnabled = canUseAdminCommands,
        onUse = function(ctx)
            API.requestResetIcon(ctx.text)
        end,
    },
    CommandStream:new {
        name = 'addlanguage',
        command = '/addlanguage ',
        helpTextID = 'UI_OmiChat_HelpText_AddLanguage',
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
                    return not API.checkPlayerKnowsLanguage(username, result)
                end,
            },
        },
        isEnabled = canUseAdminCommands,
        onUse = function(ctx)
            API.requestAddLanguage(ctx.text)
        end,
    },
    CommandStream:new {
        name = 'resetlanguages',
        command = '/resetlanguages ',
        helpTextID = 'UI_OmiChat_HelpText_ResetLanguages',
        suggestSpec = { 'online-username-with-self' },
        isEnabled = canUseAdminCommands,
        onUse = function(ctx)
            API.requestResetLanguages(ctx.text)
        end,
    },
    CommandStream:new {
        name = 'setlanguageslots',
        command = '/setlanguageslots ',
        helpTextID = 'UI_OmiChat_HelpText_SetLanguageSlots',
        suggestSpec = { 'online-username-with-self' },
        isEnabled = canUseAdminCommands,
        onUse = function(ctx)
            API.requestSetLanguageSlots(ctx.text)
        end,
    },
    CommandStream:new {
        name = 'emotes',
        command = '/emotes ',
        helpTextID = 'UI_OmiChat_HelpText_Emotes',
        isEnabled = function() return config:isEmoteMacroEnabled() end,
        onUse = function(ctx) ctx.stream:onHelp() end,
        onHelp = function()
            -- collect currently available emotes
            local emotes = {}
            for k in pairs(API._emotes) do
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

            API.addInfoMessage(concat(parts))
        end,
    },
    CommandStream:new {
        name = 'language',
        command = '/language ',
        shortCommand = '/lang ',
        helpTextID = 'UI_OmiChat_HelpText_SwitchLanguage',
        suggestSpec = { 'known-language' },
        isEnabled = function() return #API.getRoleplayLanguages() > 1 end,
        onUse = function(ctx)
            local args = utils.parseCommandArgs(ctx.text)
            local command = args[1]
            if not command then
                API.addInfoMessage(getText('UI_OmiChat_HelpText_SwitchLanguage'))
                return
            end

            local lang = matchKnownLanguage(command)
            if not lang or not API.setCurrentRoleplayLanguage(lang) then
                API.addInfoMessage(getText('UI_OmiChat_Error_SwitchUnknownLanguage', command))
                return
            end

            lang = utils.getTranslatedLanguageName(lang)
            API.addInfoMessage(getText('UI_OmiChat_Success_SwitchLanguage', lang))
        end,
    },
    CommandStream:new {
        -- reimplementing this because the vanilla clear doesn't actually clear the chatbox
        name = 'clear',
        command = '/clear ',
        isEnabled = function() return isAdmin() or isCoopHost() end,
        onUse = function()
            API.clearMessages()

            if not getDebug() then
                API.addInfoMessage(getText('UI_OmiChat_Info_Clear'))
            end
        end,
    },
    CommandStream:new {
        name = 'help',
        command = '/help ',
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
                local helpStream ---@type omichat.CommandStream?
                local helpCallback ---@type omichat.Stream.Callback.OnHelp?
                local helpText ---@type string?

                for i = 1, #API._commandStreams do
                    local stream = API._commandStreams[i]
                    if stream:getName() == command and stream:isEnabled() then
                        helpCallback = stream:getHelpCallback()
                        helpText = stream:getHelpText()
                        if helpCallback or helpText then
                            helpStream = stream
                            break
                        end
                    end
                end

                if helpStream and helpCallback then
                    helpCallback(helpStream)
                    return
                elseif helpText then
                    API.addInfoMessage(helpText)
                    return
                end

                for i = 1, #vanillaCommands do
                    local info = vanillaCommands[i]
                    if info.helpText and info.helpTextArgs then
                        API.addInfoMessage(getText(info.helpText, unpack(info.helpTextArgs)))
                        return
                    end
                end

                -- defer to default help command
                SendCommandToServer('/help ' .. command)
                return
            end

            -- overall help
            local seen = {}
            local commands = {} ---@type omichat.VanillaCommand[]

            for i = 1, #API._commandStreams do
                local stream = API._commandStreams[i]
                local name = stream:getName()
                local helpText = stream:getHelpTextStringID()
                if not seen[name] and helpText and stream:isEnabled() then
                    seen[name] = true
                    commands[#commands + 1] = { name = name, helpText = helpText, access = 0 }
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

            API.addInfoMessage(concat(result))
        end,
    },
}
