local lib = require 'OmiChat/lib'
local BaseInterpolator = lib.interpolate.Interpolator

---@class omichat.Interpolator : omi.interpolate.Interpolator
---@field private _registeredFunctions table<string, function>
local Interpolator = BaseInterpolator:derive()
Interpolator._registeredFunctions = {}

local namedEntities = {
    quot = 34,
    amp = 38,
    lt = 60,
    gt = 62,
    nbsp = 160,
    iexcl = 161,
    cent = 162,
    pound = 163,
    curren = 164,
    yen = 165,
    brvbar = 166,
    sect = 167,
    uml = 168,
    copy = 169,
    ordf = 170,
    laquo = 171,
    ['not'] = 172,
    shy = 173,
    reg = 174,
    macr = 175,
    deg = 176,
    plusmn = 177,
    sup2 = 178,
    sup3 = 179,
    acute = 180,
    micro = 181,
    para = 182,
    middot = 183,
    cedil = 184,
    sup1 = 185,
    ordm = 186,
    raquo = 187,
    frac14 = 188,
    frac12 = 189,
    frac34 = 190,
    iquest = 191,
    Agrave = 192,
    Aacute = 193,
    Acirc = 194,
    Atilde = 195,
    Auml = 196,
    Aring = 197,
    AElig = 198,
    Ccedil = 199,
    Egrave = 200,
    Eacute = 201,
    Ecirc = 202,
    Euml = 203,
    Igrave = 204,
    Iacute = 205,
    Icirc = 206,
    Iuml = 207,
    ETH = 208,
    Ntilde = 209,
    Ograve = 210,
    Oacute = 211,
    Ocirc = 212,
    Otilde = 213,
    Ouml = 214,
    times = 215,
    Oslash = 216,
    Ugrave = 217,
    Uacute = 218,
    Ucirc = 219,
    Uuml = 220,
    Yacute = 221,
    THORN = 222,
    szlig = 223,
    agrave = 224,
    aacute = 225,
    acirc = 226,
    atilde = 227,
    auml = 228,
    aring = 229,
    aelig = 230,
    ccedil = 231,
    egrave = 232,
    eacute = 233,
    ecirc = 234,
    euml = 235,
    igrave = 236,
    iacute = 237,
    icirc = 238,
    iuml = 239,
    eth = 240,
    ntilde = 241,
    ograve = 242,
    oacute = 243,
    ocirc = 244,
    otilde = 245,
    ouml = 246,
    divide = 247,
    oslash = 248,
    ugrave = 249,
    uacute = 250,
    ucirc = 251,
    uuml = 252,
    yacute = 253,
    thorn = 254,
    yuml = 255,
}


---Returns a character given a numeric character reference.
---If the argument is invalid, the original string is returned.
---@param s string A numeric character reference.
---@return string
local function resolveNumericEntity(s)
    local num = s:sub(3, #s - 1)
    local hex = num:sub(1, 1) == 'x'
    if hex then
        num = num:sub(2)
    end

    local value = tonumber(num, hex and 16 or 10)
    local success, char = pcall(string.char, value)
    return success and char or s
end

---Returns a character given a named character reference.
---If the argument is invalid, the original string is returned.
---@param s string A named character reference.
local function resolveNamedEntity(s)
    local value = namedEntities[s:sub(2, #s - 1)]
    if value then
        return string.char(value)
    end

    return s
end


---Resolves a function given its name.
---@param name string
---@return function?
function Interpolator:getFunction(name)
    if Interpolator._registeredFunctions[name] and not self._functions[name] then
        return Interpolator._registeredFunctions[name]
    end

    return BaseInterpolator.getFunction(self, name)
end

---Gets the value of an interpolation token.
---@param token unknown
---@return unknown
function Interpolator:token(token)
    if self._tokens[token] then
        return self._tokens[token]
    end

    local num = tonumber(token)
    if num and self._tokens[num] then
        return self._tokens[num]
    end

    return BaseInterpolator.token(self, token)
end

function Interpolator:interpolate(tokens)
    return Interpolator.replaceEntities(BaseInterpolator.interpolate(self, tokens))
end

---Creates a new interpolator.
---@param options omi.interpolate.Options
---@return omichat.Interpolator
function Interpolator:new(options)
    local this = BaseInterpolator.new(self, options)

    ---@cast this omichat.Interpolator
    return this
end

---Replaces character entities with the characters that they represent.
---Numeric entities and named entities in ISO-8859-1 are supported.
---@param text string
function Interpolator.replaceEntities(text)
    if not text then
        return text
    end

    return (text:gsub('&%a+;', resolveNamedEntity):gsub('&#x?%d+;', resolveNumericEntity))
end


return Interpolator
