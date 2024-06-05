local lib = require 'OmiChat/lib'
local MultiMap = lib.interpolate.MultiMap

---@class omichat.Interpolator
local Interpolator = require 'OmiChat/Component/Interpolator'

---Format string function library.
local InterpolatorLibrary = {}

local OmiChat = require 'OmiChat/API/Shared'
local utils = OmiChat.utils
local Option = OmiChat.Option

local rep = string.rep
local concat = table.concat
local baseLibraries = (require 'OmiChat/lib').interpolate.Interpolator.Libraries
local stringFunctions = baseLibraries.functions.string

local cooldowns = {}


---Colors actions in a string.
---@param s string
---@param color string
---@param autoQuote boolean
---@param excludeAsterisk boolean
---@return string, boolean
local function colorActions(s, color, autoQuote, excludeAsterisk)
    local result = {}

    local pos = 1
    local patt = autoQuote and '%*' or '"%s*%*'
    local next, nextEnd = s:find(patt)

    local endsWithAction = false
    while next and nextEnd and next <= #s do
        local sub = s:sub(pos, next - 1)
        result[#result + 1] = sub

        if not autoQuote or (autoQuote and not utils.endsWith(utils.trim(sub), '"')) then
            result[#result + 1] = '"'
        end

        result[#result + 1] = color
        result[#result + 1] = ' <SPACE> '

        if not excludeAsterisk then
            result[#result + 1] = '*'
        end

        pos = nextEnd + 1

        -- maintain action color until next quote character
        local nextQuote = s:find('"', pos)
        if not nextQuote then
            result[#result + 1] = s:sub(pos)
            result[#result + 1] = ' <SPACE> <POPRGB> '
            pos = #s + 1
            endsWithAction = true
            break
        end

        result[#result + 1] = s:sub(pos, nextQuote - 1)
        result[#result + 1] = ' <SPACE> <POPRGB> '

        pos = nextQuote
        next, nextEnd = s:find(patt, pos)
    end

    if #result == 0 then
        return s, false
    end

    if pos <= #s then
        result[#result + 1] = s:sub(pos)
    end

    return concat(result), endsWithAction
end

---Wraps a function so that it gets the internal value before being applied, and then reapplies the invisible characters.
---@param f function
---@return function
local function internalWrap(f)
    return function(interpolator, s, ...)
        local text, prefix, suffix = utils.getInternalText(tostring(s or ''))
        local result = f(interpolator, text, ...)
        return concat({ prefix, result, suffix })
    end
end

---Returns a partial quote, representing a fragment of what a player character understood.
---@param interpolator omichat.Interpolator
---@param message string
---@return string?
local function getFragmentedMessage(interpolator, message)
    local parts = message:split('\\s+')
    if #parts <= 1 then
        return
    end

    local rolls = math.min(Option.InterpretationRolls, #parts - 1)
    if rolls == 0 then
        return
    end

    -- populate and shuffle
    local indices = {}
    for i = 1, #parts do
        indices[#indices + 1] = i
    end

    for i = #indices, 2, -1 do
        local j = interpolator:random(i)
        indices[i], indices[j] = indices[j], indices[i]
    end

    -- select indices to include
    local selected = {}
    for _ = 1, rolls do
        if #indices == 0 then
            break
        end

        local chance = Option.InterpretationChance
        if interpolator:random(100) < chance then
            local choice = indices[#indices]
            indices[#indices] = nil
            selected[#selected + 1] = choice
        end
    end

    if #selected == 0 then
        return
    end

    table.sort(selected)

    -- build fragmented message
    local last = 0
    local built = {}
    for i = 1, #selected do
        local idx = selected[i]
        if idx > last + 1 then
            built[#built + 1] = '...'
        end

        built[#built + 1] = parts[idx]
        last = idx
    end

    if last < #parts then
        built[#built + 1] = '...'
    end

    return '"' .. concat(built, ' ') .. '"'
end

---Gets a string for the base unknown language string, without a message fragment.
---@param language string
---@param stream string?
---@param author string?
---@param dialogueTag string?
---@return string?
local function getBaseUnknownLanguageString(language, stream, author, dialogueTag)
    language = language and tostring(language) or ''
    if language == '' then
        return
    end

    stream = stream and tostring(stream) or 'say'
    author = author and tostring(author) or ''

    if stream == 'radio' and author == '' then
        return getText('UI_OmiChat_UnknownLanguageRadioNoAuthor', language)
    end

    local isSigned = OmiChat.isRoleplayLanguageSigned(language)
    language = utils.getTranslatedLanguageName(language)

    -- narrative style
    dialogueTag = dialogueTag and tostring(dialogueTag) or ''
    if author ~= '' and dialogueTag ~= '' then
        local stringID = 'UI_OmiChat_UnknownLanguageNarrative_' .. dialogueTag:gsub('%s', '_')

        local translated = getTextOrNull(stringID, author, language)
        if translated then
            return translated
        end

        stringID = 'UI_OmiChat_UnknownLanguageNarrative_' .. (isSigned and 'signs' or 'says')
        return getText(stringID, author, language)
    end

    local stringID = { 'UI_OmiChat_UnknownLanguage' }
    if isSigned then
        stringID[#stringID + 1] = 'Signed'
    end

    if stream == 'whisper' then
        stringID[#stringID + 1] = 'Whisper'
    elseif stream == 'shout' then
        stringID[#stringID + 1] = 'Shout'
    else
        stringID[#stringID + 1] = 'Say'
    end

    return getText(concat(stringID), language)
end

---Stringifies inputs into a single delimited string.
---@param sep string
---@param ... unknown
---@return string
local function stringifySep(sep, ...)
    local t = {}
    for i = 1, select('#', ...) do
        t[#t + 1] = tostring(select(i, ...) or '')
    end

    return concat(t, sep)
end

---Stringifies inputs into a single string.
---@param ... unknown
---@return string
local function stringify(...)
    return stringifySep('', ...)
end


local library
library = {
    capitalize = internalWrap(stringFunctions.capitalize),
    punctuate = internalWrap(stringFunctions.punctuate),
    ---@param _ omichat.Interpolator
    ---@param ... unknown
    ---@return string, string, string
    internal = function(_, ...)
        return utils.getInternalText(stringify(...))
    end,
    ---@param _ omichat.Interpolator
    ---@param s string?
    ---@param category omichat.ColorCategory?
    ---@return string?
    colorquotes = function(_, s, category)
        ---@cast OmiChat omichat.api.client
        if not OmiChat.getColorOrDefault then
            return
        end

        s = tostring(s or '')
        if s == '' then
            return
        end

        if category == '' then
            category = nil
        end

        category = tostring(category or 'say')
        local color = utils.toChatColor(OmiChat.getColorOrDefault(category), true)
        if color == '' then
            return s
        end

        s = s:gsub('%b""', function(quote)
            return concat {
                ' <SPACE>',
                color,
                quote,
                ' <POPRGB> <SPACE> ',
            }
        end)

        return s
    end,
    ---@param interpolator omichat.Interpolator
    ---@param s string
    ---@param category omichat.ColorCategory?
    ---@param includeAsterisk string?
    ---@param autoQuote string?
    ---@return string?
    coloractions = function(interpolator, s, category, includeAsterisk, autoQuote)
        ---@cast OmiChat omichat.api.client
        if not OmiChat.getColorOrDefault then
            return
        end

        s = tostring(s or '')
        if s == '' then
            return
        end

        if category == '' then
            category = nil
        end

        local color = utils.toChatColor(OmiChat.getColorOrDefault(tostring(category or 'me')), true)

        -- narrative style handling
        local prefix = ''
        local suffix = ''
        if interpolator:token('dialogueTag') then
            local startQ = s:find('"')
            local endQ = s:sub(#s, #s)

            if startQ and endQ == '"' and startQ ~= endQ then
                prefix = s:sub(1, startQ)
                suffix = '"'
                s = s:sub(startQ + 1, #s - 1)
            end
        end

        local doAutoQuote = interpolator:toBoolean(autoQuote)
        local doExcludeAsterisk = not interpolator:toBoolean(includeAsterisk)
        local delimited, endsWithAction = colorActions(s, color, doAutoQuote, doExcludeAsterisk)
        if not delimited then
            return
        end

        -- if we end with an action or a quote, get rid of the trailing quote
        if endsWithAction or utils.endsWith(delimited, '"') then
            suffix = ''
        end

        return prefix .. delimited .. suffix
    end,
    ---@param _ omichat.Interpolator
    ---@param s string
    ---@return string
    stripcolors = function(_, s)
        s = tostring(s or ''):gsub('<RGB:[%d,.]*>', '')
        return s
    end,
    ---@param _ omichat.Interpolator
    ---@param language string
    ---@return boolean
    issigned = function(_, language)
        return OmiChat.isRoleplayLanguageSigned(tostring(language or ''))
    end,
    accesslevel = function()
        local player = getSpecificPlayer(0)
        return player and player:getAccessLevel() or 'none'
    end,
    isadmin = function()
        if isAdmin() then
            return 'true'
        end
    end,
    iscoophost = function()
        if isCoopHost() then
            return 'true'
        end
    end,
    escaperichtext = function(_, ...)
        return utils.escapeRichText(stringify(...))
    end,
    ---@param interpolator omichat.Interpolator
    ---@param message string
    ---@return string?
    fragmented = function(interpolator, message)
        message = message and tostring(message) or ''
        return getFragmentedMessage(interpolator, message)
    end,
    ---@param interpolator omichat.Interpolator
    ---@param language string
    ---@param stream string?
    ---@param author string?
    ---@param dialogueTag string?
    ---@param noQuoteColor string?
    ---@return string?
    getunknownlanguagestring = function(interpolator, language, stream, author, dialogueTag, noQuoteColor)
        local base = getBaseUnknownLanguageString(language, stream, author, dialogueTag)
        if not base then
            return
        end

        local message = tostring(interpolator:token('unstyled') or interpolator:token('message') or '')
        local fragment = getFragmentedMessage(interpolator, message)
        if not fragment then
            return base
        end

        local parts = { base, ' <SPACE> ' }

        local pop
        if not interpolator:toBoolean(noQuoteColor) then
            ---@cast OmiChat omichat.api.client
            local color = OmiChat.getColorOrDefault and utils.toChatColor(OmiChat.getColorOrDefault('say'), true) or ''
            if color ~= '' then
                pop = true
                parts[#parts + 1] = color
            end
        end

        parts[#parts + 1] = fragment
        parts[#parts + 1] = pop and ' <POPRGB> ' or ''

        return concat(parts)
    end,
    ---@param name string
    ---@return omichat.ChatCommandType?
    streamtype = function(_, name)
        ---@cast OmiChat omichat.api.client
        if not OmiChat.getChatStreamByIdentifier then
            return
        end

        local stream = OmiChat.getChatStreamByIdentifier(name)
        if not stream then
            return
        end

        return stream:getCommandType()
    end,

    fmtcard = function(_, ...)
        return getText('UI_OmiChat_CardLocal', stringify(...))
    end,
    fmtroll = function(_, roll, ...)
        roll = tostring(roll or '')
        return getText('UI_OmiChat_RollLocal', roll, stringify(...))
    end,
    ---@param interpolator omichat.Interpolator
    ---@param heads string?
    ---@return string
    fmtflip = function(interpolator, heads)
        local s = interpolator:toBoolean(heads) and 'Heads' or 'Tails'
        return getText('UI_OmiChat_FlipLocal' .. s)
    end,
    fmtradio = function(_, ...)
        return getText('UI_OmiChat_Radio', stringify(...))
    end,
    fmtrp = function(_, ...)
        return getText('UI_OmiChat_RPEmote', stringifySep(' ', ...))
    end,
    ---@param name string
    ---@param parenCount string?
    ---@return string
    fmtpmfrom = function(_, name, parenCount)
        local s = getText('UI_OmiChat_PrivateChatFrom', tostring(name or ''))
        local parens = tonumber(parenCount)
        if not parens or parens <= 0 then
            return s
        end

        return rep('(', parens) .. s .. rep(')', parens)
    end,
    ---@param name string
    ---@param parenCount string?
    ---@return string
    fmtpmto = function(_, name, parenCount)
        local s = getText('UI_OmiChat_PrivateChatTo', tostring(name or ''))
        local parens = tonumber(parenCount)
        if not parens or parens <= 0 then
            return s
        end

        return rep('(', parens) .. s .. rep(')', parens)
    end,
    ---@param interpolator omichat.Interpolator
    ---@param names omi.interpolate.MultiMap
    ---@param alt string?
    ---@return string?
    fmttyping = function(interpolator, names, alt)
        if interpolator:toBoolean(alt) then
            return getText('UI_OmiChat_TypingMany')
        elseif utils.isinstance(names, MultiMap) then
            local size = names:size()
            if size == 0 then
                return
            end

            local text
            if size < 4 then
                local list = {}
                for _, el in names:values() do
                    list[#list + 1] = el
                end

                text = getText('UI_OmiChat_Typing' .. size, unpack(list))
            else
                text = getText('UI_OmiChat_TypingMany')
            end

            return text
        end
    end,
    parens = function(_, ...)
        return '(' .. stringifySep(' ', ...) .. ')'
    end,

    ---@param interpolator omichat.Interpolator
    ---@param condition string?
    ---@param suppressError string?
    ---@return boolean success
    disallowsignedoverradio = function(interpolator, condition, suppressError)
        if not interpolator:toBoolean(condition) then
            return true
        end

        local language = interpolator:token('languageRaw')
        if not language or not OmiChat.isRoleplayLanguageSigned(language) then
            return true
        end

        if suppressError then
            return false
        end

        local errorID = 'UI_OmiChat_Error_SignedRadio'
        local stream = interpolator:token('stream')
        if stream == 'safehouse' then
            errorID = 'UI_OmiChat_Error_SignedSafehouseRadio'
        elseif stream == 'faction' then
            errorID = 'UI_OmiChat_Error_SignedFactionRadio'
        end

        interpolator:setToken('errorID', errorID)
        return false
    end,
    ---@param interpolator omichat.Interpolator
    ---@param n unknown?
    ---@param key string?
    ---@param suppressError string?
    ---@return boolean
    cooldown = function(interpolator, n, key, suppressError)
        n = tonumber(n)
        if not n then
            return true
        end

        local now = getTimestampMs()

        key = tostring(key or '')
        if key == '' then
            key = interpolator:token('stream')
        end

        local next = cooldowns[key]
        if not next or next <= now then
            cooldowns[key] = now + n * 1000
            return true
        end

        if suppressError then
            return false
        end

        local errorID = 'UI_OmiChat_Error_CommandCooldown'
        local remaining = math.ceil((next - now) / 1000)
        if remaining <= 1 then
            errorID = 'UI_OmiChat_Error_CommandCooldown1'
        end

        interpolator:setToken('error', getText(errorID, remaining))
        return false
    end,
    ---@param interpolator omichat.Interpolator
    ---@param key string?
    ---@param n unknown?
    cooldownset = function(interpolator, key, n)
        n = tonumber(n)
        if not n then
            return
        end

        key = tostring(key or '')
        if key == '' then
            key = interpolator:token('stream')
        end

        if n <= 0 then
            cooldowns[key] = nil
        else
            cooldowns[key] = getTimestampMs() + n * 1000
        end
    end,
    ---@param interpolator omichat.Interpolator
    ---@param condition string?
    ---@param n unknown?
    ---@param key string?
    ---@param suppressError string?
    ---@return boolean
    cooldownif = function(interpolator, condition, n, key, suppressError)
        if not interpolator:toBoolean(condition) then
            return true
        end

        return library.cooldown(interpolator, n, key, suppressError)
    end,
    ---@param interpolator omichat.Interpolator
    ---@param condition string?
    ---@param n unknown?
    ---@param key string?
    ---@param suppressError string?
    ---@return boolean
    cooldownunless = function(interpolator, condition, n, key, suppressError)
        if interpolator:toBoolean(condition) then
            return true
        end

        return library.cooldown(interpolator, n, key, suppressError)
    end,
    ---@param interpolator omichat.Interpolator
    ---@param key string?
    ---@return number?
    cooldownremaining = function(interpolator, key)
        key = tostring(key or '')
        if key == '' then
            key = interpolator:token('stream')
        end

        local now = getTimestampMs()
        local next = cooldowns[key]
        if not next or next <= now then
            return
        end

        return math.ceil((next - now) / 1000)
    end,
}


---Loads the library into the destination table.
---@param dest table
function InterpolatorLibrary:load(dest)
    for k, v in pairs(library) do
        dest[k] = v
    end
end


Interpolator.CustomLibrary = InterpolatorLibrary
InterpolatorLibrary.library = library
return InterpolatorLibrary
