---Command stream definition for `/addlanguage`.
---@namespace omichat

local API = require 'OmiChat/Module/Client/Core'

return API.CommandStream:new {
    name = 'addlanguage',
    command = '/addlanguage ',
    helpTextID = 'help-text-add-language',
    isEnabled = API.player.canUseAdminCommands,
    defaultOnDisabled = false,
    onUse = function(ctx)
        API.request.executeCommand('addLanguage', ctx.text)
    end,
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
                return not API.language.doesPlayerKnow(username, result)
            end,
        },
    },
}
