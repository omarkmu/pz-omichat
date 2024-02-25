---@class omichat.Interpolator
local Interpolator = require 'OmiChat/Component/Interpolator'

local InterpolatorLibrary = {}

local OmiChat = require 'OmiChat/API/Shared'
local lib = require 'OmiChat/lib'
local utils = require 'OmiChat/util'

local concat = table.concat
local baseLibraries = lib.interpolate.Interpolator.Libraries
local stringFunctions = baseLibraries.functions.string


local function internalWrap(f)
    return function(interpolator, s, ...)
        local text, prefix, suffix = utils.getInternalText(tostring(s or ''))
        local result = f(interpolator, text, ...)
        return concat({ prefix, result, suffix })
    end
end

local library = {
    capitalize = internalWrap(stringFunctions.capitalize),
    punctuate = internalWrap(stringFunctions.punctuate),
    ---@param _ omichat.Interpolator
    ---@param ... unknown
    ---@return string, string, string
    internal = function(_, ...)
        local t = {}
        for i = 1, select('#', ...) do
            t[#t + 1] = tostring(select(i, ...) or '')
        end

        return utils.getInternalText(concat({ ... }))
    end,
    ---@param _ omichat.Interpolator
    ---@param s string?
    ---@param category omichat.ColorCategory
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
