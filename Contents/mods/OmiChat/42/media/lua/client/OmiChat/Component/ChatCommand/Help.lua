---Command stream definition for `/help`.
---@namespace omichat

local API = require 'OmiChat/Module/Client/Core'
local vanillaCommands = require 'OmiChat/Definition/VanillaCommandList'
local utils = API.utils

local concat = table.concat
local getTextVanilla = getText
local getText = utils.getText
local getTextOrNull = utils.getTextOrNull
local CAPABILITY_NONE = Capability.None

return API.CommandStream:new {
    name = 'help',
    command = '/help ',
    onUse = function(ctx)
        local role = API.player.getRole()
        local command = ctx.text
        if not role then
            -- player unavailable, defer to default help command
            SendCommandToServer('/help ' .. command)
            return
        end

        command = utils.trim(command)

        -- specific command help
        if #command > 0 then
            for stream in API.streams.commandStreams() do
                if stream:getName() == command and stream:isEnabled() and stream:onHelp() then
                    return
                end
            end

            for i = 1, #vanillaCommands do
                local info = vanillaCommands[i]
                if info.helpText and info.helpTextArgs then
                    API.chat.addInfoMessage(getTextVanilla(info.helpText, unpack(info.helpTextArgs)))
                    return
                end
            end

            -- defer to default help command
            SendCommandToServer('/help ' .. command)
            return
        end

        -- overall help
        local seen = {}
        local commands = {} ---@type VanillaCommand[]

        for stream in API.streams.commandStreams() do
            local name = stream:getName()
            if not seen[name] and stream:isEnabled() then
                seen[name] = true

                local helpText = stream:getHelpTextStringID()
                if helpText then
                    commands[#commands + 1] = {
                        name = name,
                        helpText = helpText,
                        capability = CAPABILITY_NONE,
                    }
                end
            end
        end

        for i = 1, #vanillaCommands do
            local info = vanillaCommands[i]
            if info.name and not seen[info.name] then
                if role:hasCapability(info.capability) then
                    commands[#commands + 1] = info
                end
            end
        end

        table.sort(commands, function(a, b) return a.name < b.name end)

        local result = { getText('info-command-list') }
        for i = 1, #commands do
            local cmd = commands[i]
            result[#result + 1] = ' <LINE> * '
            result[#result + 1] = cmd.name
            result[#result + 1] = ' : '

            if not cmd.helpText then
                result[#result + 1] = '?'
            elseif cmd.helpTextArgs then
                result[#result + 1] = getTextVanilla(cmd.helpText, unpack(cmd.helpTextArgs))
            else
                result[#result + 1] = getTextOrNull(cmd.helpText) or getTextVanilla(cmd.helpText)
            end
        end

        API.chat.addInfoMessage(concat(result))
    end,
}
