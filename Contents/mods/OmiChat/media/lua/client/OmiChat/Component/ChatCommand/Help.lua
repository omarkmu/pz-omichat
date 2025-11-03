---Command stream definition for `/help`.
---@namespace omichat

local API = require 'OmiChat/Module/Client/Core'
local vanillaCommands = require 'OmiChat/Definition/VanillaCommandList'

local concat = table.concat
local utils = API.utils


return API.CommandStream:new {
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
            for stream in API.streams.commandStreams() do
                if stream:getName() == command and stream:isEnabled() and stream:onHelp() then
                    return
                end
            end

            for i = 1, #vanillaCommands do
                local info = vanillaCommands[i]
                if info.helpText and info.helpTextArgs then
                    API.chat.addInfoMessage(getText(info.helpText, unpack(info.helpTextArgs)))
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

        API.chat.addInfoMessage(concat(result))
    end,
}
