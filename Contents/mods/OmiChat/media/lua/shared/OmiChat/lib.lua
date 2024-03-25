---@format disable
---@diagnostic disable: codestyle-check, name-style-check, no-unknown, redefined-local, spell-check, unused-local
local require, __bundle_register = (function(_require)
	local require
	local loadingPlaceholder = {}
	local modules = {}
    local loaded = {}

	require = function(name)
		local ret = loaded[name]
		if loadingPlaceholder == ret then
            return
        elseif ret == nil then
			if not modules[name] then
                return _require(name)
			end

			loaded[name] = loadingPlaceholder
			ret = modules[name](require)

			if ret == nil then
				loaded[name] = true
			else
				loaded[name] = ret
			end
		end

		return ret
	end

	return require, function(name, body)
		if not modules[name] then
			modules[name] = body
		end
	end
end)(require)
__bundle_register("interpolate", function(require)
---Module containing functionality for string interpolation.
---@class omi.interpolate
local interpolate = {}

---@type omi.interpolate.Parser
interpolate.Parser = require("interpolate/Parser")

---@type omi.interpolate.Interpolator
interpolate.Interpolator = require("interpolate/Interpolator")

---@type omi.interpolate.MultiMap
interpolate.MultiMap = require("interpolate/MultiMap")


---Performs string interpolation.
---@param text string
---@param tokens table?
---@param options omi.interpolate.Options?
---@return string
function interpolate.interpolate(text, tokens, options)
    ---@type omi.interpolate.Interpolator
    local interpolator = interpolate.Interpolator:new(options)
    interpolator:setPattern(text)

    return interpolator:interpolate(tokens)
end


setmetatable(interpolate, {
    __call = function(self, ...) return self.interpolate(...) end,
})

---@diagnostic disable-next-line: cast-type-mismatch
---@cast interpolate omi.interpolate | (fun(text: string, tokens: table?, options: omi.interpolate.Options?): string)
return interpolate

end)
__bundle_register("interpolate/MultiMap", function(require)
local utils = require("utils")
local class = require("class")
local entry = require("interpolate/entry")


---Immutable set of key-value entries which permits multiple entries with the same key.
---@class omi.interpolate.MultiMap
---@field protected _entries omi.interpolate.entry[]
---@field protected _map table<unknown, unknown>
---@diagnostic disable-next-line: assign-type-mismatch
local MultiMap = class()


---Returns an iterator for the entries in this multimap.
---@return function
function MultiMap:pairs()
    local i = 0
    return function()
        i = i + 1
        local e = self._entries[i]
        if e then
            return e.key, e.value
        end
    end
end

---Returns an iterator for the keys in this multimap.
---@return function
function MultiMap:keys()
    return utils.mapList(function(e) return e.key end, self._entries)
end

---Returns an iterator for the values in this multimap.
---@return function
function MultiMap:values()
    return utils.mapList(function(e) return e.value end, self._entries)
end

---Concatenates the stringified values of this multimap.
---@param sep string? The separator to use.
---@param i integer? The start index.
---@param j integer? The end index.
---@return string
function MultiMap:concat(sep, i, j)
    return utils.concat(utils.mapList(tostring, self:pairs()), sep, i, j)
end

---Returns the value of the first entry in the multimap.
---@return unknown?
function MultiMap:first()
    local e = self._entries[1]
    if e then
        return e.value
    end
end

---Returns the value of the last entry in the multimap.
---@return unknown?
function MultiMap:last()
    local e = self._entries[#self._entries]
    if e then
        return e.value
    end
end

---Returns the nth entry in the multimap.
---@param n integer
---@return omi.interpolate.entry?
function MultiMap:entry(n)
    local e = self._entries[n]
    if e then
        return utils.copy(e)
    end
end

---Returns the number of entries in this multimap.
---@return integer
function MultiMap:size()
    return #self._entries
end

---Returns a multimap with only the unique values from this multimap.
---@return omi.interpolate.MultiMap
function MultiMap:unique()
    local seen = {}
    local entries = {}
    for key, value in self:pairs() do
        if not seen[value] then
            entries[#entries + 1] = entry(key, value)
            seen[value] = true
        end
    end

    return MultiMap:new(entries)
end

---Returns true if there is a value associated with the given key.
---@param key unknown
---@return boolean
function MultiMap:has(key)
    return self._map[key] ~= nil
end

---Gets the first value associated with a key.
---@param key unknown The key to query.
---@param default unknown? A default value to return if there are no entries associated with the key.
---@return unknown?
function MultiMap:get(key, default)
    local list = self._map[key]
    if not list then
        return default
    end

    return list[1].value
end

---Gets a MultiMap of entries associated with a key.
---@param key unknown The key to query.
---@param default unknown? A default value to return if there are no entries associated with the key.
---@return unknown?
function MultiMap:index(key, default)
    if not self:has(key) then
        return default
    end

    return MultiMap:new(self._map[key])
end

---Creates a new multimap.
---@param ... (omi.interpolate.entry[] | omi.interpolate.MultiMap) Sources to copy entries from.
---@return omi.interpolate.MultiMap
function MultiMap:new(...)
    local this = setmetatable({}, self)

    local entries = {}
    local map = {}
    for i = 1, select('#', ...) do
        local iter
        local source = select(i, ...)

        if utils.isinstance(source, MultiMap) then
            ---@cast source omi.interpolate.MultiMap
            iter = source.pairs
        elseif type(source) == 'table' then
            iter = ipairs
        end

        if iter then
            for _, e in iter(source) do
                entries[#entries + 1] = e

                if not map[e.key] then
                    map[e.key] = {}
                end

                local mapEntries = map[e.key]
                mapEntries[#mapEntries + 1] = entry(#mapEntries + 1, e.value)
            end
        end
    end

    this._entries = entries
    this._map = map
    return this
end

MultiMap.__tostring = function(self)
    return tostring(self:first() or '')
end

MultiMap.__len = function(self)
    return self:size()
end


return MultiMap

end)
__bundle_register("interpolate/entry", function(require)
---@class omi.interpolate.entry
---@field key unknown
---@field value unknown

---Returns an entry with the specified key and value.
---@param key unknown
---@param value unknown
---@return omi.interpolate.entry
return function(key, value)
    return { key = key, value = value }
end

end)
__bundle_register("class", function(require)
---@diagnostic disable: inject-field
local setmetatable = setmetatable


---Base class for lightweight classes.
---@class omi.Class
local Class = {}

---Module containing functionality related to creating lightweight classes.
---@class omi.class
local class = {}


---Creates a new class.
local function createClass(cls, base)
    if not base then
        base = Class
    end

    cls = cls or {}
    cls.__index = cls
    base.__index = base

    return setmetatable(cls, base)
end


---Creates a new subclass.
---@param cls table?
---@return omi.Class
function Class:derive(cls)
    return class.derive(self, cls)
end

---Creates a new subclass.
---@param base table
---@param cls table?
---@return omi.Class
function class.derive(base, cls)
    return createClass(cls, base)
end

---Creates a new class.
---@param cls table?
---@return omi.Class
function class.new(cls)
    return createClass(cls)
end


setmetatable(class, {
    __call = function(self, ...) return self.new(...) end,
})


---@diagnostic disable-next-line: cast-type-mismatch
---@cast class omi.class | (fun(cls: table?): omi.Class)
return class

end)
__bundle_register("utils", function(require)
---Module containing utility functions.
---@class omi.utils : omi.utils.string, omi.utils.table, omi.utils.type
local utils = {}


---@type omi.utils.json
utils.json = require("utils/json")


local submodules = {
    require("utils/string"),
    require("utils/table"),
    require("utils/type"),
}

for i = 1, #submodules do
    for k, v in pairs(submodules[i]) do
        utils[k] = v
    end
end


return utils

end)
__bundle_register("utils/type", function(require)
local deepEquals
local rawget = rawget
local getmetatable = getmetatable
local unpack = unpack or table.unpack ---@diagnostic disable-line: deprecated


---Utilities related to types.
---@class omi.utils.type
local utils = {}


---Checks two values for deep equality.
---@param t1 unknown
---@param t2 unknown
---@param seen table<table, boolean>
---@return boolean
deepEquals = function(t1, t2, seen)
    if type(t1) ~= 'table' then
        return t1 == t2
    elseif type(t1) ~= type(t2) then
        return false
    end

    local t1Meta = getmetatable(t1)
    local t2Meta = getmetatable(t2)

    if seen[t1] then
        return seen[t1] == t2
    end

    if (t1Meta and rawget(t1, '__eq')) or (t2Meta and rawget(t2, '__eq')) then
        return t1 == t2
    end

    local visitedKeys = {}
    seen[t1] = t2
    seen[t2] = t1

    for k, v in pairs(t1) do
        visitedKeys[k] = true
        if not deepEquals(v, t2[k], seen) then
            return false
        end
    end

    for k, v in pairs(t2) do
        if not visitedKeys[k] and not deepEquals(t1[k], v, seen) then
            return false
        end
    end

    return true
end


---Creates a new function given arguments that precede any provided arguments when `func` is called.
---@param func any
---@param ... unknown
---@return function
function utils.bind(func, ...)
    local nArgs = select('#', ...)
    local boundArgs = { ... }

    return function(...)
        local args = { unpack(boundArgs, 1, nArgs) }
        local nNewArgs = select('#', ...)
        for i = 1, nNewArgs do
            args[nArgs + i] = select(i, ...)
        end

        return func(unpack(args, 1, nArgs + nNewArgs))
    end
end

---Checks whether two objects have equivalent values.
---For non-tables, this is equivalent to an equality check.
---Comparison is done by comparing every element.
---Assumes keys are not relevant for deep equality.
---@param t1 unknown
---@param t2 unknown
---@return boolean
function utils.deepEquals(t1, t2)
    return deepEquals(t1, t2, {})
end

---Returns `value` if non-nil. Otherwise, returns `default`.
---@param value? unknown
---@param default unknown
---@return unknown
function utils.default(value, default)
    if value ~= nil then
        return value
    end

    return default
end

---Traverses the metatable chain to determine whether an object is an instance of a class.
---@param obj table?
---@param cls table?
---@return boolean
function utils.isinstance(obj, cls)
    if not obj or not cls then
        return false
    end

    local seen = {}
    local meta = getmetatable(obj)
    while meta and not seen[meta] do
        if type(meta) ~= 'table' then
            return false
        end

        if rawget(meta, '__index') == cls then
            return true
        end

        seen[meta] = true
        meta = getmetatable(meta)
    end

    return false
end


return utils

end)
__bundle_register("utils/table", function(require)
---Utilities related to tables and functions.
---@class omi.utils.table
local utils = {}


---Returns whether the result of `func` is truthy for all values in `target`.
---@param predicate fun(arg): unknown Predicate function.
---@param target table | (fun(...): unknown) Key-value iterator function or table.
---@param ... unknown Iterator state.
---@return boolean
function utils.all(predicate, target, ...)
    if type(target) == 'table' then
        return utils.all(predicate, pairs(target))
    end

    for _, v in target, ... do
        if not predicate(v) then
            return false
        end
    end

    return true
end

---Returns whether the result of `func` is truthy for any value in `target`.
---@param predicate fun(arg): unknown Predicate function.
---@param target table | (fun(...): unknown) Key-value iterator function or table.
---@param ... unknown Iterator state.
---@return boolean
function utils.any(predicate, target, ...)
    if type(target) == 'table' then
        return utils.any(predicate, pairs(target))
    end

    for _, v in target, ... do
        if predicate(v) then
            return true
        end
    end

    return false
end

---Concatenates a table or stateful iterator function.
---If the input is a table, elements will be converted to strings.
---@param target table | function List or key-value iterator function.
---@param sep string? The separator to use between elements.
---@param i integer? The index at which concatenation should start.
---@param j integer? The index at which concatenation should stop.
---@return string
function utils.concat(target, sep, i, j)
    if type(target) == 'function' then
        target = utils.pack(target)
    else
        target = utils.pack(utils.map(tostring, target))
    end

    return table.concat(target, sep or '', i or 1, j or #target)
end

---Returns a shallow copy of a table.
---@param table table
---@return table
function utils.copy(table)
    local copy = {}

    for k, v in pairs(table) do
        copy[k] = v
    end

    return copy
end

---Returns an iterator with only the values in `target` for which `predicate` is truthy.
---@param predicate fun(value): unknown Predicate function.
---@param target table | (fun(...): unknown) Key-value iterator function or table.
---@param ... unknown Iterator state.
---@return function
function utils.filter(predicate, target, ...)
    if type(target) == 'table' then
        return utils.filter(predicate, pairs(target))
    end

    local value
    local state, control = ...
    return function()
        while true do
            control, value = target(state, control)
            if control == nil then
                break
            end

            if predicate(value) then
                return control, value
            end
        end
    end
end

---Returns an iterator which maps all elements of `target` to the return value of `func`.
---@param func fun(value: unknown, key: unknown): unknown Map function.
---@param target table | (fun(...): unknown) Key-value iterator function or table.
---@param ... unknown Iterator state.
---@return function
function utils.map(func, target, ...)
    if type(target) == 'table' then
        return utils.map(func, pairs(target))
    end

    local value
    local state, control = ...
    return function()
        control, value = target(state, control)
        if control ~= nil then
            return control, func(value, control)
        end
    end
end

---Returns an iterator which maps all elements of `target` to the return value of `func`.
---@param func fun(value: unknown, key: unknown, index: integer): unknown Map function.
---@param target unknown[] | (fun(...): unknown) Key-value iterator function or list.
---@param ... unknown Iterator state.
---@return function
function utils.mapList(func, target, ...)
    if type(target) == 'table' then
        return utils.mapList(func, ipairs(target))
    end

    local idx = 0
    local value
    local state, control = ...
    return function()
        control, value = target(state, control)
        if control ~= nil then
            idx = idx + 1
            return idx, func(value, control, idx)
        end
    end
end

---Packs the pairs from an iterator into a table.
---@param iter fun(...): unknown, unknown Key-value iterator function.
---@param ... unknown Iterator state.
---@return table
function utils.pack(iter, ...)
    if type(iter) == 'table' then
        return iter
    end

    local packed = {}
    for k, v in iter, ... do
        packed[k] = v
    end

    return packed
end

---Applies `acc` cumulatively to all elements of `target` and returns the final value.
---@param acc fun(result: unknown, element: unknown, key: unknown): unknown Reducer function.
---@param initial unknown? Initial value.
---@param target table | (fun(...): unknown, unknown) Key-value iterator function or table.
---@param ... unknown Iterator state.
---@return unknown
function utils.reduce(acc, initial, target, ...)
    if type(target) == 'table' then
        return utils.reduce(acc, initial, pairs(target))
    end

    local value = initial
    for k, v in target, ... do
        if initial == nil then
            value = v
            initial = true
        else
            value = acc(value, v, k)
        end
    end

    return value
end

---Applies `acc` cumulatively to all elements of `target` and returns the final value.
---Assumes a given table is an array and orders elements accordingly; for maps, use `reduce`.
---@param acc fun(result: unknown, element: unknown, key: unknown): unknown Reducer function.
---@param initial unknown? Initial value.
---@param target table | (fun(...): unknown) Key-value iterator function or list.
---@param ... unknown Iterator state.
---@return unknown
function utils.reduceList(acc, initial, target, ...)
    if type(target) == 'table' then
        return utils.reduce(acc, initial, ipairs(target))
    end

    return utils.reduce(acc, initial, target, ...)
end


return utils

end)
__bundle_register("utils/string", function(require)
---Module containing utilities related to formatting and handling strings.
---@class omi.utils.string
local utils = {}


local iso8859Entities = {
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


---Tests if a table is empty or has only keys from `1` to `#t`.
---@param t table
---@return boolean
local function isArray(t)
    local i = 0
    for _ in pairs(t) do
        i = i + 1
        if t[i] == nil then
            return false
        end
    end

    return true
end

---Stringifies a non-table value.
---@param value unknown
---@return string
local function stringifyPrimitive(value)
    if type(value) == 'string' then
        return string.format('%q', value)
    end

    return tostring(value)
end

---Stringifies a table.
---@param t table
---@param seen table
---@param pretty boolean?
---@param depth number?
---@param maxDepth number?
---@return string
local function stringifyTable(t, seen, pretty, depth, maxDepth)
    depth = depth or 1
    maxDepth = maxDepth or 5

    local mt = getmetatable(t)
    if mt and mt.__tostring then
        return tostring(t)
    end

    if seen[t] then
        return '{...}'
    end

    seen[t] = true

    local isNumeric = isArray(t)
    local space = pretty and '\n' or ' '
    local tab = pretty and string.rep('    ', depth) or ''
    local keyEnd = pretty and '] = ' or ']='

    local result = {
        '{',
        space,
    }

    local iter = isNumeric and ipairs or pairs
    local isFirst = true

    for k, v in iter(t) do
        if not isFirst then
            result[#result + 1] = ','
            result[#result + 1] = space
        end

        isFirst = false

        result[#result + 1] = tab

        if not isNumeric then
            result[#result + 1] = '['
            if type(k) == 'table' then
                -- don't show table keys
                result[#result + 1] = '{...}'
            else
                result[#result + 1] = stringifyPrimitive(k)
            end

            result[#result + 1] = keyEnd
        end

        if type(v) == 'table' then
            result[#result + 1] = stringifyTable(v, seen, pretty, depth + 1, maxDepth)
        else
            result[#result + 1] = stringifyPrimitive(v)
        end
    end

    result[#result + 1] = pretty and (space .. string.rep('    ', depth - 1)) or space
    result[#result + 1] = '}'

    return table.concat(result)
end


---Returns text that's safe for use in a pattern.
---@param text string
---@return string
function utils.escape(text)
    return (text:gsub('([[%]%+%-%*?().^$%%])', '%%%1'))
end

---Returns the value of a numeric character reference or character entity reference.
---If the value cannot be resolved, returns `nil`.
---@param entity string
---@return string?
function utils.getEntityValue(entity)
    if entity:sub(1, 1) ~= '&' or entity:sub(#entity) ~= ';' then
        return
    end

    entity = entity:sub(2, #entity - 1)
    if entity:sub(1, 1) ~= '#' then
        local value = iso8859Entities[entity]
        if value then
            return string.char(value)
        end
    end

    local hex = entity:sub(2, 2) == 'x'
    local num = entity:sub(hex and 3 or 2)

    local value = tonumber(num, hex and 16 or 10)
    if not value then
        return
    end

    local success, char = pcall(string.char, value)
    if not success then
        return
    end

    return char
end

---Removes whitespace from either side of a string.
---@param text string
---@return string
function utils.trim(text)
    return (text:gsub('^%s*(.-)%s*$', '%1'))
end

---Removes whitespace from the start of a string.
---@param text string
---@return string
function utils.trimleft(text)
    return (text:gsub('^%s*(.*)', '%1'))
end

---Removes whitespace from the end of a string.
---@param text string
---@return string
function utils.trimright(text)
    return (text:gsub('(.-)%s*$', '%1'))
end

---Returns true if `text` contains `other`.
---@param text string
---@param other string
---@return boolean
function utils.contains(text, other)
    if not other then
        return false
    elseif #other == 0 then
        return true
    end

    return text:find(other, 1, true) ~= nil
end

---Returns whether a string starts with another string.
---@param text string
---@param other string
---@return boolean
function utils.startsWith(text, other)
    if not other then
        return false
    end

    return text:sub(1, #other) == other
end

---Returns whether a string ends with another string.
---@param text string
---@param other string
---@return boolean
function utils.endsWith(text, other)
    if not other then
        return false
    elseif #other == 0 then
        return true
    end

    local len = #other
    return text:sub(-len) == other
end

---Stringifies a value for display.
---For non-tables, this is equivalent to `tostring`.
---Tables will stringify their values unless a `__tostring` method is present on their metatable.
---@param value unknown
---@param pretty boolean? If true, tables will include newlines and tabs.
---@param maxDepth number? Maximum table depth. Defaults to 5.
---@return string
function utils.stringify(value, pretty, maxDepth)
    if type(value) ~= 'table' then
        return tostring(value)
    end

    return stringifyTable(value, {}, pretty, 1, maxDepth)
end


return utils

end)
__bundle_register("utils/json", function(require)
--
-- json.lua
--
-- Copyright (c) 2020 rxi
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy of
-- this software and associated documentation files (the "Software"), to deal in
-- the Software without restriction, including without limitation the rights to
-- use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
-- of the Software, and to permit persons to whom the Software is furnished to do
-- so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.
--

---Utilities related to handling JSON.
---@class omi.utils.json
local json = {}

---@alias omi.JSONType table | string | number | boolean | nil


--#region encode

local encode

local escape_char_map = {
    ['\\'] = '\\',
    ['\"'] = '\"',
    ['\b'] = 'b',
    ['\f'] = 'f',
    ['\n'] = 'n',
    ['\r'] = 'r',
    ['\t'] = 't',
}

local escape_char_map_inv = { ['/'] = '/' }
for k, v in pairs(escape_char_map) do
    escape_char_map_inv[v] = k
end


local function escape_char(c)
    return '\\' .. (escape_char_map[c] or string.format('u%04x', c:byte()))
end


---@diagnostic disable-next-line: unused-local
local function encode_nil(val)
    return 'null'
end


local function is_empty(tab)
    if next then
        return next(tab) == nil
    end

    for _ in pairs(tab) do
        return false
    end

    return true
end


local function encode_table(val, stack)
    local res = {}
    stack = stack or {}

    -- Circular reference?
    if stack[val] then error('circular reference') end

    stack[val] = true

    if rawget(val, 1) ~= nil or is_empty(val) then
        -- Treat as array -- check keys are valid and it is not sparse
        local n = 0
        for k in pairs(val) do
            if type(k) ~= 'number' then
                error('invalid table: mixed or invalid key types')
            end

            n = n + 1
        end

        if n ~= #val then
            error('invalid table: sparse array')
        end

        -- Encode
        for i = 1, #val do
            table.insert(res, encode(val[i], stack))
        end

        stack[val] = nil
        return '[' .. table.concat(res, ',') .. ']'
    else
        -- Treat as an object
        for k, v in pairs(val) do
            if type(k) ~= 'string' then
                error('invalid table: mixed or invalid key types')
            end

            table.insert(res, encode(k, stack) .. ':' .. encode(v, stack))
        end

        stack[val] = nil
        return '{' .. table.concat(res, ',') .. '}'
    end
end


local function encode_string(val)
    return '"' .. val:gsub('[%z\1-\31\\"]', escape_char) .. '"'
end


local function encode_number(val)
    -- Check for NaN, -inf and inf
    if val ~= val or val <= -math.huge or val >= math.huge then
        error("unexpected number value '" .. tostring(val) .. "'")
    end

    return string.format('%.14g', val)
end


local type_func_map = {
    ['nil'] = encode_nil,
    ['table'] = encode_table,
    ['string'] = encode_string,
    ['number'] = encode_number,
    ['boolean'] = tostring,
}


encode = function(val, stack)
    local t = type(val)
    local f = type_func_map[t]
    if f then
        return f(val, stack)
    end

    error("unexpected type '" .. t .. "'")
end


---Encodes a value as JSON.
---@param val omi.JSONType
---@return string
function json.encode(val)
    return (encode(val))
end

---Tries to encode a value as JSON.
---@param val omi.JSONType
---@return boolean success
---@return string resultOrError
function json.tryEncode(val)
    local s, e = pcall(json.encode, val)
    return s, e
end

--#endregion


--#region decode

local parse

local function create_set(...)
    local res = {}
    for i = 1, select('#', ...) do
        res[select(i, ...)] = true
    end

    return res
end

local space_chars = create_set(' ', '\t', '\r', '\n')
local delim_chars = create_set(' ', '\t', '\r', '\n', ']', '}', ',')
local escape_chars = create_set('\\', '/', '"', 'b', 'f', 'n', 'r', 't', 'u')
local literals = create_set('true', 'false', 'null')

local literal_map = {
    ['true'] = true,
    ['false'] = false,
    ['null'] = nil,
}


local function next_char(str, idx, set, negate)
    for i = idx, #str do
        if set[str:sub(i, i)] ~= negate then
            return i
        end
    end

    return #str + 1
end

local function decode_error(str, idx, msg)
    local line_count = 1
    local col_count = 1
    for i = 1, idx - 1 do
        col_count = col_count + 1
        if str:sub(i, i) == '\n' then
            line_count = line_count + 1
            col_count = 1
        end
    end

    error(string.format('%s at line %d col %d', msg, line_count, col_count))
end

local function codepoint_to_utf8(n)
    -- http://scripts.sil.org/cms/scripts/page.php?site_id=nrsi&id=iws-appendixa
    local f = math.floor
    if n <= 0x7f then
        return string.char(n)
    elseif n <= 0x7ff then
        return string.char(f(n / 64) + 192, n % 64 + 128)
    elseif n <= 0xffff then
        return string.char(f(n / 4096) + 224, f(n % 4096 / 64) + 128, n % 64 + 128)
    elseif n <= 0x10ffff then
        return string.char(f(n / 262144) + 240, f(n % 262144 / 4096) + 128, f(n % 4096 / 64) + 128, n % 64 + 128)
    end

    error(string.format("invalid unicode codepoint '%x'", n))
end

local function parse_unicode_escape(s)
    local n1 = tonumber(s:sub(1, 4), 16)
    local n2 = tonumber(s:sub(7, 10), 16)

    -- Surrogate pair?
    if n2 then
        return codepoint_to_utf8((n1 - 0xd800) * 0x400 + (n2 - 0xdc00) + 0x10000)
    else
        return codepoint_to_utf8(n1)
    end
end

local function parse_string(str, i)
    local res = ''
    local j = i + 1
    local k = j

    while j <= #str do
        local x = str:byte(j)

        if x < 32 then
            decode_error(str, j, 'control character in string')
        elseif x == 92 then -- `\`: Escape
            res = res .. str:sub(k, j - 1)
            j = j + 1
            local c = str:sub(j, j)
            if c == 'u' then
                local hex = str:match('^[dD][89aAbB]%x%x\\u%x%x%x%x', j + 1)
                    or str:match('^%x%x%x%x', j + 1)
                    or decode_error(str, j - 1, 'invalid unicode escape in string')
                res = res .. parse_unicode_escape(hex)
                j = j + #hex
            else
                if not escape_chars[c] then
                    decode_error(str, j - 1, "invalid escape char '" .. c .. "' in string")
                end

                res = res .. escape_char_map_inv[c]
            end

            k = j + 1
        elseif x == 34 then -- `"`: End of string
            res = res .. str:sub(k, j - 1)
            return res, j + 1
        end

        j = j + 1
    end

    decode_error(str, i, 'expected closing quote for string')
end

local function parse_number(str, i)
    local x = next_char(str, i, delim_chars)
    local s = str:sub(i, x - 1)
    local n = tonumber(s)
    if not n then
        decode_error(str, i, "invalid number '" .. s .. "'")
    end

    return n, x
end

local function parse_literal(str, i)
    local x = next_char(str, i, delim_chars)
    local word = str:sub(i, x - 1)
    if not literals[word] then
        decode_error(str, i, "invalid literal '" .. word .. "'")
    end

    return literal_map[word], x
end

local function parse_array(str, i)
    local res = {}
    local n = 1
    i = i + 1
    while 1 do
        local x
        i = next_char(str, i, space_chars, true)
        -- Empty / end of array?
        if str:sub(i, i) == ']' then
            i = i + 1
            break
        end

        -- Read token
        x, i = parse(str, i)
        res[n] = x
        n = n + 1
        -- Next token
        i = next_char(str, i, space_chars, true)
        local chr = str:sub(i, i)
        i = i + 1
        if chr == ']' then break end

        if chr ~= ',' then decode_error(str, i, "expected ']' or ','") end
    end

    return res, i
end

local function parse_object(str, i)
    local res = {}
    i = i + 1
    while 1 do
        local key, val
        i = next_char(str, i, space_chars, true)
        -- Empty / end of object?
        if str:sub(i, i) == '}' then
            i = i + 1
            break
        end

        -- Read key
        if str:sub(i, i) ~= '"' then
            decode_error(str, i, 'expected string for key')
        end

        key, i = parse(str, i)
        -- Read ':' delimiter
        i = next_char(str, i, space_chars, true)
        if str:sub(i, i) ~= ':' then
            decode_error(str, i, "expected ':' after key")
        end

        i = next_char(str, i + 1, space_chars, true)
        -- Read value
        val, i = parse(str, i)
        -- Set
        res[key] = val
        -- Next token
        i = next_char(str, i, space_chars, true)
        local chr = str:sub(i, i)
        i = i + 1
        if chr == '}' then break end

        if chr ~= ',' then decode_error(str, i, "expected '}' or ','") end
    end

    return res, i
end


local char_func_map = {
    ['"'] = parse_string,
    ['0'] = parse_number,
    ['1'] = parse_number,
    ['2'] = parse_number,
    ['3'] = parse_number,
    ['4'] = parse_number,
    ['5'] = parse_number,
    ['6'] = parse_number,
    ['7'] = parse_number,
    ['8'] = parse_number,
    ['9'] = parse_number,
    ['-'] = parse_number,
    ['t'] = parse_literal,
    ['f'] = parse_literal,
    ['n'] = parse_literal,
    ['['] = parse_array,
    ['{'] = parse_object,
}


parse = function(str, idx)
    local chr = str:sub(idx, idx)
    local f = char_func_map[chr]
    if f then
        return f(str, idx)
    end

    decode_error(str, idx, "unexpected character '" .. chr .. "'")
end


---Decodes a JSON string.
---@param str string
---@return omi.JSONType
function json.decode(str)
    if type(str) ~= 'string' then
        error('expected argument of type string, got ' .. type(str))
    end

    local res, idx = parse(str, next_char(str, 1, space_chars, true))
    idx = next_char(str, idx, space_chars, true)
    if idx <= #str then
        decode_error(str, idx, 'trailing garbage')
    end

    return res
end

---Tries to decode a JSON string.
---@param str string
---@return boolean success
---@return omi.JSONType resultOrError
function json.tryDecode(str)
    local s, e = pcall(json.decode, str)
    return s, e
end

--#endregion


return json

end)
__bundle_register("interpolate/Interpolator", function(require)
local table = table
local unpack = unpack or table.unpack ---@diagnostic disable-line: deprecated
local newrandom = newrandom
local class = require("class")
local utils = require("utils")
local entry = require("interpolate/entry")
local MultiMap = require("interpolate/MultiMap")
local InterpolatorLibraries = require("interpolate/Libraries")
local InterpolationParser = require("interpolate/Parser")
local NodeType = InterpolationParser.NodeType


---Handles string interpolation.
---@class omi.interpolate.Interpolator : omi.Class
---@field protected _tokens table<string, unknown>
---@field protected _functions table<string, function>
---@field protected _library table<string, function>
---@field protected _built omi.interpolate.Node[]
---@field protected _allowTokens boolean
---@field protected _allowMultiMaps boolean
---@field protected _allowFunctions boolean
---@field protected _allowCharacterEntities boolean
---@field protected _requireCustomTokenUnderscore boolean
---@field protected _parser omi.interpolate.Parser
---@field protected _rand Random?
local Interpolator = class()

---@type omi.interpolate.Libraries
Interpolator.Libraries = InterpolatorLibraries

---@class omi.interpolate.Options
---@field pattern string? The initial format string of the interpolator.
---@field allowTokens boolean? Whether tokens should be interpreted. If false, tokens will be treated as text.
---@field allowCharacterEntities boolean? Whether character entities should be interpreted. If false, they will be treated as text.
---@field allowMultiMaps boolean? Whether at-maps should be interpreted. If false, they will be treated as text.
---@field allowFunctions boolean? Whether functions should be interpreted. If false, they will be treated as text.
---@field requireCustomTokenUnderscore boolean? Whether custom tokens should require a leading underscore.
---@field libraryInclude table<string, boolean>? Set of library functions or modules to allow. If absent, all will be allowed.
---@field libraryExclude table<string, boolean>? Set of library functions or modules to exclude. If absent, none will be excluded.


---Merges a table of parts.
---If only one part is present, it is returned as-is. Otherwise, the parts are stringified and concatenated.
---@param parts table
---@return unknown
local function mergeParts(parts)
    if #parts == 1 then
        return parts[1]
    end

    return utils.concat(parts)
end


---Evaluates a tree node.
---@param node omi.interpolate.Node The input tree node.
---@param target table? Table to which the result will be appended.
---@return table #Returns the table provided for `target`.
---@protected
function Interpolator:evaluateNode(node, target)
    target = target or {}

    local type = node.type
    local result
    if type == NodeType.text then
        result = node.value
    elseif self._allowTokens and type == NodeType.token then
        result = self:token(node.value)
    elseif self._allowMultiMaps and type == NodeType.at_expression then
        ---@cast node omi.interpolate.AtExpressionNode
        result = self:evaluateAtExpression(node)
    elseif self._allowFunctions and type == NodeType.call then
        ---@cast node omi.interpolate.CallNode
        result = self:evaluateCallNode(node)
    end

    if result then
        target[#target + 1] = self:convert(result)
    end

    return target
end

---Evaluates a node array as a single expression.
---This is used for handling at-map key/value expressions.
---@param nodes omi.interpolate.ValueNode[]
---@return unknown?
---@protected
function Interpolator:evaluateNodeArray(nodes)
    if not nodes then
        return
    end

    local parts = {}
    for i = 1, #nodes do
        self:evaluateNode(nodes[i], parts)
    end

    return mergeParts(parts)
end

---Evaluates an at map expression.
---@param node omi.interpolate.AtExpressionNode
---@return omi.interpolate.MultiMap
---@protected
function Interpolator:evaluateAtExpression(node)
    if not node.entries then
        return MultiMap:new()
    end

    ---@type omi.interpolate.entry[]
    local entries = {}
    for i = 1, #node.entries do
        local e = node.entries[i]
        local key = self:evaluateNodeArray(e.key)
        local value = self:evaluateNodeArray(e.value)

        if value and not e.key then
            if utils.isinstance(value, MultiMap) then
                -- @(@(A;B) @(C)) → @(A;B;C)
                ---@cast value omi.interpolate.MultiMap
                for entryKey, entryValue in value:pairs() do
                    if self:toBoolean(entryKey) then
                        entries[#entries + 1] = entry(entryKey, entryValue)
                    end
                end
            else
                -- @(A) → @(A:A)
                local keyValue = tostring(value)
                if self:toBoolean(keyValue) then
                    entries[#entries + 1] = entry(keyValue, value)
                end
            end
        elseif utils.isinstance(key, MultiMap) then
            -- @(@(A;B): C) → @(A:C;B:C)
            ---@cast key omi.interpolate.MultiMap
            for _, entryValue in key:pairs() do
                local keyValue = tostring(entryValue)
                if self:toBoolean(keyValue) then
                    entries[#entries + 1] = entry(keyValue, value)
                end
            end
        elseif self:toBoolean(key) then
            -- @(A:B)
            entries[#entries + 1] = entry(key, value)
        end
    end

    return MultiMap:new(entries)
end

---Evaluates a function call expression.
---@param node omi.interpolate.CallNode
---@return unknown?
---@protected
function Interpolator:evaluateCallNode(node)
    local args = {}

    for i = 1, #node.args do
        local argument = node.args[i]
        local parts = {}

        for j = 1, #argument do
            self:evaluateNode(argument[j], parts)
        end

        args[i] = self:convert(mergeParts(parts))
    end

    return self:execute(node.value, args)
end

---Returns a random number.
---@param m integer?
---@param n integer?
---@return number
function Interpolator:random(m, n)
    -- for testing in other environments
    if math.random then
        if m and n then
            return math.random(math.floor(m), math.floor(n))
        elseif m then
            return math.random(math.floor(m))
        end

        return math.random()
    end

    if not self._rand then
        self._rand = newrandom()
    end

    return self._rand:random(m, n)
end

---Returns a random element from a table of options.
---@param options table
---@return unknown?
function Interpolator:randomChoice(options)
    if #options == 0 then
        return
    end

    -- for testing in other environments
    if math.random then
        return options[math.random(#options)]
    end

    if not self._rand then
        self._rand = newrandom()
    end

    return options[self._rand:random(#options)]
end

---Sets the random seed for this interpolator.
---@param seed unknown
function Interpolator:randomseed(seed)
    if math.randomseed then
        -- enable testing in other environments
        seed = tonumber(seed)
        if seed then
            math.randomseed(seed)
        end

        return
    end

    if not self._rand then
        self._rand = newrandom()
    end

    self._rand:seed(seed)
end

---Performs string interpolation and returns a string.
---@param tokens table? Interpolation tokens. If excluded, the current tokens will be unchanged.
---@return string
function Interpolator:interpolate(tokens)
    return tostring(self:interpolateRaw(tokens))
end

---Performs string interpolation.
---@param tokens table? Interpolation tokens. If excluded, the current tokens will be unchanged.
---@return string
function Interpolator:interpolateRaw(tokens)
    if tokens then
        self._tokens = tokens
    end

    local parts = {}
    for i = 1, #self._built do
        self:evaluateNode(self._built[i], parts)
    end

    return mergeParts(parts)
end

---Converts a value to a type that can be used in interpolation functions.
---@param value unknown
---@return unknown
function Interpolator:convert(value)
    if type(value) == 'string' then
        return value
    end

    if utils.isinstance(value, MultiMap) then
        return self._allowMultiMaps and value or tostring(value)
    end

    if not value then
        return ''
    end

    return tostring(value)
end

---Converts a value to a boolean using interpolator logic.
---@param value unknown
---@return boolean
function Interpolator:toBoolean(value)
    if utils.isinstance(value, MultiMap) then
        value = tostring(value)
    end

    return value and value ~= ''
end

---Resolves a function given its name.
---@param name string
---@return function?
function Interpolator:getFunction(name)
    return self._functions[name] or self._library[name]
end

---Executes an interpolation function.
---@param name string
---@param args unknown[]
---@return unknown?
function Interpolator:execute(name, args)
    name = name:lower()
    local func = self:getFunction(name)
    if not func then
        return
    end

    return func(self, unpack(args))
end

---Gets the value of an interpolation token.
---@param token unknown
---@return unknown
function Interpolator:token(token)
    return self._tokens[token]
end

---Sets the value of an interpolation token.
---@param token unknown
---@param value unknown
function Interpolator:setToken(token, value)
    self._tokens[token] = value
end

---Sets the value of an interpolation token with additional validation.
---This is called by the $set interpolator function.
---@param token unknown
---@param value unknown
function Interpolator:setTokenValidated(token, value)
    if self._requireCustomTokenUnderscore and token:sub(1, 1) ~= '_' and self:token(token) == nil then
        return
    end

    self:setToken(token, self:convert(value))
end

---Sets the interpolation pattern to use and builds the interpolation tree.
---@param pattern string
function Interpolator:setPattern(pattern)
    pattern = pattern or ''

    if not self._parser then
        self._parser = self:createParser(pattern)
    else
        self._parser:reset(pattern)
    end

    local result = self._parser:parse()
    if not result.success then
        local list = {}
        for i = 1, #result.errors do
            list[#list + 1] = result.errors[i].message
        end

        local errors = table.concat(list, ', ')
        error(string.format('interpolation of pattern `%s` failed: %s', pattern, errors))
    end

    self._built = result.value
end

---Sets library functions which should be allowed and disallowed.
---@param include table<string, true>? A set of functions or modules to allow.
---@param exclude table<string, true>? A set of functions or modules to disallow.
function Interpolator:loadLibraries(include, exclude)
    self._library = InterpolatorLibraries:load(include, exclude)
end

---Creates a parser for this interpolator.
---@param pattern string
---@return omi.interpolate.Parser
---@protected
function Interpolator:createParser(pattern)
    return InterpolationParser:new(pattern, {
        allowTokens = self._allowTokens,
        allowFunctions = self._allowFunctions,
        allowAtExpressions = self._allowMultiMaps,
        allowCharacterEntities = self._allowCharacterEntities,
    })
end

---Creates a new interpolator.
---@param options omi.interpolate.Options?
---@return omi.interpolate.Interpolator
function Interpolator:new(options)
    options = options or {}

    ---@type omi.interpolate.Interpolator
    local this = setmetatable({}, self)

    this._tokens = {}
    this._functions = {}
    this._library = {}
    this._built = {}
    this._allowTokens = utils.default(options.allowTokens, true)
    this._allowMultiMaps = utils.default(options.allowMultiMaps, true)
    this._allowFunctions = utils.default(options.allowFunctions, true)
    this._allowCharacterEntities = utils.default(options.allowCharacterEntities, true)
    this._requireCustomTokenUnderscore = utils.default(options.requireCustomTokenUnderscore, true)

    this:loadLibraries(options.libraryInclude, options.libraryExclude)
    this:setPattern(options.pattern)

    return this
end


return Interpolator

end)
__bundle_register("interpolate/Parser", function(require)
local BaseParser = require("fmt/Parser")
local utils = require("utils")

local concat = table.concat


---Parser for the interpolated string format.
---@class omi.interpolate.Parser : omi.fmt.Parser
---@field protected _allowTokens boolean
---@field protected _allowAtExpr boolean
---@field protected _allowFunctions boolean
---@field protected _allowCharEntities boolean
local InterpolationParser = BaseParser:derive()


---@class omi.interpolate.ParserOptions : omi.fmt.ParserOptions
---@field allowTokens boolean?
---@field allowFunctions boolean?
---@field allowAtExpressions boolean?
---@field allowCharacterEntities boolean?

---@alias omi.interpolate.Result
---| { success: true, value: omi.interpolate.Node[], warnings: omi.fmt.ParserError[]? }
---| { success: false, errors: omi.fmt.ParserError[], warnings: omi.fmt.ParserError[]? }

---@alias omi.interpolate.Node
---| omi.interpolate.ValueNode
---| omi.interpolate.CallNode
---| omi.interpolate.AtExpressionNode

---@alias omi.interpolate.Argument omi.interpolate.ValueNode[]

---@class omi.interpolate.ValueNode
---@field type omi.interpolate.NodeType
---@field value string

---@class omi.interpolate.CallNode : omi.interpolate.ValueNode
---@field args omi.interpolate.Node[][]

---@class omi.interpolate.AtExpressionEntry
---@field key omi.interpolate.ValueNode[]
---@field value omi.interpolate.ValueNode[]

---@class omi.interpolate.AtExpressionNode
---@field type omi.interpolate.NodeType
---@field entries omi.interpolate.AtExpressionEntry[]


---@alias omi.interpolate.NodeType
---| 'at_expression'
---| 'at_key'
---| 'at_value'
---| 'text'
---| 'token'
---| 'string'
---| 'call'
---| 'escape'
---| 'argument'

---@type table<omi.interpolate.NodeType, string>
InterpolationParser.NodeType = {
    at_expression = 'at_expression',
    at_key = 'at_key',
    at_value = 'at_value',
    text = 'text',
    token = 'token',
    string = 'string',
    call = 'call',
    escape = 'escape',
    argument = 'argument',
}

local NodeType = InterpolationParser.NodeType
local ERR = {
    BAD_CHAR = 'unexpected character: `%s`',
    WARN_UNTERM_FUNC = 'potentially unterminated function `%s`',
    UNTERM_FUNC = 'unterminated function `%s`',
    UNTERM_AT = 'unterminated at-expression',
}

-- text patterns for node types
local TEXT_PATTERNS = {
    -- $ = token/escape/call start, space = delimiter, ( = string start, ) = call end, & = entity start
    [NodeType.argument] = ' $%(%)&',
    -- $ = token/escape/call start, @ = at-expression start, ; = delim, : = delimiter, ( = string start, ) = expression end, & = entity start
    [NodeType.at_key] = ':;$@%(%)&',
    [NodeType.at_value] = ':;$@%(%)&',
    -- $ = escape start, ) = string end
    [NodeType.string] = '$%)',
}

local SPECIAL = {
    ['$'] = true,
    ['@'] = true,
    [':'] = true,
    [';'] = true,
    ['('] = true,
    [')'] = true,
    ['&'] = true,
}


---Returns a table with consecutive text nodes merged.
---@param tab omi.fmt.ParseTreeNode[]
---@return omi.fmt.ParseTreeNode[]
---@protected
function InterpolationParser:mergeTextNodes(tab)
    local result = {}

    local last
    for i = 1, #tab do
        local node = tab[i]
        if node.type == NodeType.text then
            if last and last.parts and last.type == NodeType.text then
                last.parts[#last.parts + 1] = node.value
            else
                last = {
                    type = NodeType.text,
                    parts = { node.value },
                }

                result[#result + 1] = last
            end
        else
            result[#result + 1] = node
            last = node
        end
    end

    for i = 1, #result do
        local node = result[i]
        if node.parts and node.type == NodeType.text then
            node.value = concat(node.parts)
            node.parts = nil
        end
    end

    return result
end

---Performs postprocessing on a tree node.
---@param node omi.fmt.ParseTreeNode
---@return omi.fmt.ParseTreeNode?
---@protected
function InterpolationParser:postprocessNode(node)
    local nodeType = node.type

    if nodeType == NodeType.text or nodeType == NodeType.escape then
        return {
            type = NodeType.text,
            value = node.value,
        }
    elseif nodeType == NodeType.token then
        return {
            type = nodeType,
            value = node.value,
        }
    elseif nodeType == NodeType.string then
        -- convert string to basic text node
        local parts = {}
        if node.children then
            for i = 1, #node.children do
                local built = self:postprocessNode(node.children[i])
                if built and built.value then
                    parts[#parts + 1] = built.value
                end
            end
        end

        return {
            type = NodeType.text,
            value = concat(parts),
        }
    elseif nodeType == NodeType.argument or nodeType == NodeType.at_key or nodeType == NodeType.at_value then
        -- convert node to list of child nodes
        local parts = {}
        if node.children then
            for i = 1, #node.children do
                local built = self:postprocessNode(node.children[i])
                if built then
                    parts[#parts + 1] = built
                end
            end
        end

        return self:mergeTextNodes(parts)
    elseif nodeType == NodeType.call then
        local args = {}

        if node.children then
            for i = 1, #node.children do
                local child = node.children[i]
                local type = child.type
                if type == NodeType.argument then
                    args[#args + 1] = self:postprocessNode(child)
                end
            end
        end

        return {
            type = node.type,
            value = node.value,
            args = args,
        }
    elseif nodeType == NodeType.at_expression then
        local children = node.children or {}
        local entries = {}

        local i = 1
        while i <= #children do
            local key = children[i]
            local builtKey = key and key.type == NodeType.at_key and self:postprocessNode(key)

            if builtKey then
                local value = children[i + 1]
                local builtValue = value and value.type == NodeType.at_value and self:postprocessNode(value)

                if builtValue then
                    entries[#entries + 1] = {
                        key = builtKey,
                        value = builtValue,
                    }

                    i = i + 1
                else
                    builtValue = builtKey
                    entries[#entries + 1] = {
                        value = builtValue,
                    }
                end
            end

            i = i + 1
        end

        return {
            type = NodeType.at_expression,
            entries = entries,
        }
    end
end

---Gets the value of a named or numeric entity.
---@param entity string
---@return string
---@protected
function InterpolationParser:getEntityValue(entity)
    return utils.getEntityValue(entity) or entity
end

---Gets the pattern for text nodes given the current node type.
---@return string
---@protected
function InterpolationParser:getTextPattern()
    local type = self._node and self._node.type

    -- $ = token/escape/call start, @ = at-expression start, & = entity start
    local patt = TEXT_PATTERNS[type] or '$@&'
    return string.format('^([^%s])[%s]?', patt, patt)
end

---Reads space characters and returns a literal string of spaces.
---@return string?
---@protected
function InterpolationParser:readSpaces()
    local spaces = self:match('^( +)')
    if not spaces then
        return
    end

    self:forward(#spaces)
    return spaces
end

---Reads a prefix followed by an escaped character.
---@return omi.fmt.ParseTreeNode?
---@protected
function InterpolationParser:readEscape()
    local value = self:match('^$([$@();:&])')
    if not value then
        return
    end

    local node = self:createNode(NodeType.escape, { value = value })

    self:setNodeEnd(node, self:pos() + 1)
    self:forward(2)

    return self:addNode(node)
end

---Reads as much text as possible, up to the next special character.
---@return omi.fmt.ParseTreeNode?
---@protected
function InterpolationParser:readText()
    local value = self:match(self:getTextPattern())
    if not value then
        return
    end

    local node = self:createNode(NodeType.text, { value = value })

    self:setNodeEnd(node, self:pos() + #value - 1)
    self:forward(#value)

    return self:addNode(node)
end

---Reads a special character as-is.
---@return omi.fmt.ParseTreeNode?
---@protected
function InterpolationParser:readSpecialText()
    local value = self:peek()
    if not SPECIAL[value] then
        return
    end

    local node = self:createNode(NodeType.text, { value = value })
    self:forward()

    return self:addNode(node)
end

---Reads a string of literal text delimited by parentheses. Special characters can be escaped with $.
---@return omi.fmt.ParseTreeNode?
---@protected
function InterpolationParser:readString()
    if self:peek() ~= '(' then
        return
    end

    local stop
    local node = self:createNode(NodeType.string)
    local parent = self:setCurrentNode(node)
    self:forward()

    while self:pos() <= self:len() do
        if self:peek() == ')' then
            break
        end

        if not (self:readEscape() or self:readText() or self:readSpecialText()) then
            self:errorHere(ERR.BAD_CHAR:format(self:peek()), node)
            stop = self:pos() - 1

            break
        end
    end

    self:setNodeEnd(node, stop)
    self:setCurrentNode(parent)

    if self:peek() ~= ')' then
        -- unterminated string; read as open parenthesis and rewind
        self:pos(node.range[1])
        node = self:createNode(NodeType.text, { value = '(' })
    end

    self:forward()
    return self:addNode(node)
end

---Reads a variable token (e.g., `$var`).
---@return omi.fmt.ParseTreeNode?
---@protected
function InterpolationParser:readVariable()
    if not self._allowTokens then
        return
    end

    local name, pos = self:match('^$([%w_]+)()')

    if not name then
        return
    end

    local node = self:createNode(NodeType.token, { value = name })
    self:setNodeEnd(node, pos - 1)
    self:pos(pos)

    return self:addNode(node)
end

---Reads a character entity (e.g., `&#171;`)
---@return omi.fmt.ParseTreeNode?
---@protected
function InterpolationParser:readCharacterEntity()
    if not self._allowCharEntities then
        return
    end

    local entity, pos = self:match('^(&#x?%d+;)()')

    if not entity then
        entity, pos = self:match('^(&%a+;)()')
        if not entity then
            return
        end
    end

    local value = self:getEntityValue(entity)
    if not value then
        return
    end

    local node = self:createNode(NodeType.text, { value = value })
    self:setNodeEnd(node, pos - 1)
    self:pos(pos)

    return self:addNode(node)
end

---Reads a function and its arguments (e.g., `$upper(hello)`).
---@return omi.fmt.ParseTreeNode?
---@protected
function InterpolationParser:readFunction()
    if not self._allowFunctions then
        return
    end

    local name, start = self:match('^$([%w_]+)%(()')
    if not name then
        return
    end

    local node = self:createNode(NodeType.call, { value = name })
    local parent = self:setCurrentNode(node)
    self:pos(start)

    local argNode = self:createNode(NodeType.argument)
    self:setCurrentNode(argNode)

    local stop
    while self:pos() <= self:len() do
        local delimited = self:readSpaces()
        local done = self:peek() == ')'
        if delimited or done then
            self:setCurrentNode(node)

            if argNode.children and #argNode.children > 0 then
                self:addNode(argNode)
            end

            if done or self:pos() > self:len() then
                break
            end

            argNode = self:createNode(NodeType.argument)
            self:setCurrentNode(argNode)
        end

        if not (self:readString() or self:readExpression()) then
            self:errorHere(ERR.BAD_CHAR:format(self:peek()), argNode)
            stop = self:pos() - 1

            break
        end
    end

    self:setCurrentNode(parent)

    if self:peek() ~= ')' then
        -- unterminated function; read as var and rewind
        self:pos(node.range[1])

        local variableNode = self:readVariable()
        if variableNode then
            self:warning(ERR.WARN_UNTERM_FUNC:format(name), node)
            return variableNode
        end

        self:error(ERR.UNTERM_FUNC:format(name), node)
    end

    self:setNodeEnd(node, stop)
    self:forward()
    return self:addNode(node)
end

---Reads an at-expression (e.g., `@(1)`, `@(A:B)`, `@(1;A:B)`).
---@return omi.fmt.ParseTreeNode?
---@protected
function InterpolationParser:readAtExpression()
    if not self._allowAtExpr then
        return
    end

    local start = self:match('^@%(()')
    if not start then
        return
    end

    local node = self:createNode(NodeType.at_expression)
    local parent = self:setCurrentNode(node)
    self:pos(start)

    local stop, keyNode, valueNode

    self:readSpaces()

    while self:pos() <= self:len() do
        while self:peek() == ';' do
            keyNode = nil
            valueNode = nil
            self:forward()
        end

        if self:pos() > self:len() then
            break
        end

        if not keyNode then
            self:readSpaces()
        end

        local c = self:peek()
        if c == ')' then
            break
        elseif c == ':' then
            local keyPos = self:pos()

            -- consume :
            repeat
                self:forward()
            until self:peek() ~= ':'

            if self:pos() > self:len() then
                break
            end

            self:setCurrentNode(node)

            -- existing value node | no key node → add empty key node
            if valueNode or not keyNode then
                keyNode = self:addNode(self:createNode(NodeType.at_key))
                self:setNodeRange(keyNode, keyPos, keyPos)
            end

            self:readSpaces()

            valueNode = self:addNode(self:createNode(NodeType.at_value))
            self:setCurrentNode(valueNode)
        elseif not keyNode then
            self:setCurrentNode(node)
            keyNode = self:addNode(self:createNode(NodeType.at_key))
            self:setCurrentNode(keyNode)
        end

        c = self:peek()
        if c == ';' or c == ':' then
            -- ignore; avoid reading invalid value
        elseif c == ')' then
            if valueNode then
                local pos = self:pos()
                self:setNodeRange(valueNode, pos, pos)
            end

            break
        elseif not (self:readString() or self:readExpression()) then
            self:errorHere(ERR.BAD_CHAR:format(self:peek()), valueNode or keyNode or node)

            stop = self:pos() - 1
            self:setNodeEnd(self._node, stop)

            break
        elseif keyNode or valueNode then
            self:setNodeEnd(self._node, self:pos() - 1)
        end
    end

    self:setNodeEnd(node, stop)
    self:setCurrentNode(parent)

    if self:peek() ~= ')' then
        -- unterminated expression; read @ and rewind
        self:warning(ERR.UNTERM_AT, node)
        self:pos(node.range[1])
        node = self:createNode(NodeType.text, { value = '@' })
    end

    self:forward()
    return self:addNode(node)
end

---Reads a single acceptable expression.
---@return omi.fmt.ParseTreeNode?
---@protected
function InterpolationParser:readExpression()
    return self:readEscape()
        or self:readFunction()
        or self:readVariable()
        or self:readAtExpression()
        or self:readCharacterEntity()
        or self:readText()
        or self:readSpecialText()
end

---Performs postprocessing on a result tree.
---@return omi.interpolate.Result
---@protected
function InterpolationParser:postprocess()
    local tree = self._tree
    local result = {}
    if #self._errors > 0 then
        return {
            success = false,
            warnings = #self._warnings > 0 and self._warnings or nil,
            errors = self._errors,
        }
    end

    if not tree.children then
        return { success = true, value = result }
    end

    for i = 1, #tree.children do
        local built = self:postprocessNode(tree.children[i])
        if built then
            result[#result + 1] = built
        end
    end

    return {
        success = true,
        warnings = #self._warnings > 0 and self._warnings or nil,
        value = self:mergeTextNodes(result),
    }
end

---Performs parsing and returns a list of interpolate nodes.
---@return omi.interpolate.Result
function InterpolationParser:parse()
    return BaseParser.parse(self)
end

---Creates a new interpolation parser.
---@param text string
---@param options omi.interpolate.ParserOptions?
---@return omi.interpolate.Parser
function InterpolationParser:new(text, options)
    local this = BaseParser.new(self, text, options)
    ---@cast this omi.interpolate.Parser

    options = options or {}

    this._allowTokens = utils.default(options.allowTokens, true)
    this._allowAtExpr = utils.default(options.allowAtExpressions, true)
    this._allowFunctions = utils.default(options.allowFunctions, true)
    this._allowCharEntities = utils.default(options.allowCharacterEntities, true)

    return this
end


return InterpolationParser

end)
__bundle_register("fmt/Parser", function(require)
local math = math
local class = require("class")
local utils = require("utils/type")


---Base string parser.
---@class omi.fmt.Parser : omi.Class
---@field protected _errors omi.fmt.ParserError[]
---@field protected _warnings omi.fmt.ParserError[]
---@field protected _ptr integer
---@field protected _text string
---@field protected _node omi.fmt.ParseTreeNode?
---@field protected _tree omi.fmt.ParseTree
---@field protected _treeNodeType string?
---@field protected _raiseErrors boolean
local Parser = class()


---Base parser options.
---@class omi.fmt.ParserOptions
---@field raiseErrors boolean?
---@field treeNodeType string?

---Describes error that occurred during parsing.
---@class omi.fmt.ParserError
---@field message string
---@field node omi.fmt.ParseTreeNode?
---@field range integer[]

---Describes a node in a parse tree.
---@class omi.fmt.ParseTreeNode
---@field type string
---@field range integer[]
---@field value string?
---@field children omi.fmt.ParseTreeNode[]?

---Top-level parse tree node.
---@class omi.fmt.ParseTree : omi.fmt.ParseTreeNode
---@field source string


---Moves the parser pointer forward.
---@param inc integer? The value to move forward by. Defaults to 1.
---@protected
function Parser:forward(inc)
    self:pos(self:pos() + (inc or 1))
end

---Moves the parser pointer backwards.
---@param inc integer? The value to move backwards by. Defaults to 1.
---@protected
function Parser:rewind(inc)
    self:pos(self:pos() - (inc or 1))
end

---Gets the current `n` bytes at the current pointer.
---@param n integer? The number of bytes to get. Defaults to 1.
---@return string
---@protected
function Parser:peek(n)
    return self:index(self:pos(), n or 1)
end

---Reads the current `n` bytes at the current pointer and moves the pointer forward.
---@param n integer? The number of bytes to read. Defaults to 1.
---@return string
---@protected
function Parser:read(n)
    n = n or 1

    local result = self:peek(n)
    self:forward(n)

    return result
end

---Matches a string pattern against the parser's current text.
---@param pattern string The string pattern.
---@param pos integer? A position to start from. Defaults to the current position.
---@return ...
---@protected
function Parser:match(pattern, pos)
    return self._text:match(pattern, pos or self:pos())
end

---Returns a substring of the current text.
---@param i integer The index at which the substring should begin.
---@param n integer? The number of characters to return. Defaults to 1.
---@return string
---@protected
function Parser:index(i, n)
    n = n or 1
    return self._text:sub(i, i + n - 1)
end

---Returns the length of the current text.
---@return integer
---@protected
function Parser:len()
    return #self._text
end

---Gets or sets the current pointer position.
---@param value integer?
---@return integer
---@protected
function Parser:pos(value)
    if value then
        self._ptr = value
    end

    return self._ptr
end

---Adds a node to the current tree node.
---If there is no current node, this sets the current node.
---@param node omi.fmt.ParseTreeNode The node to add.
---@return omi.fmt.ParseTreeNode node The newly added node.
---@protected
function Parser:addNode(node)
    local parent = self._node

    if not parent then
        self:setCurrentNode(node)
        return node
    end

    if not parent.children then
        parent.children = {}
    end

    parent.children[#parent.children + 1] = node

    return node
end

---Creates a new tree node.
---@param type string The node type.
---@param node table? The table to use for the node.
---@return omi.fmt.ParseTreeNode
---@protected
function Parser:createNode(type, node)
    node = node or {}
    node.type = type
    node.range = node.range or {}
    self:setNodeRange(node, node.range[1], node.range[2])

    return node
end

---Sets the current tree node and returns the old node.
---@param node omi.fmt.ParseTreeNode?
---@return omi.fmt.ParseTreeNode? oldNode
---@protected
function Parser:setCurrentNode(node)
    local old = self._node
    self._node = node

    return old
end

---Sets the range of a tree node.
---@param node omi.fmt.ParseTreeNode
---@param start integer?
---@param stop integer?
---@protected
function Parser:setNodeRange(node, start, stop)
    local len = self:len()
    local pos = self:pos()
    node.range[1] = math.max(1, math.min(start or node.range[1] or pos, len))
    node.range[2] = math.max(1, math.min(stop or node.range[2] or pos, len))
end

---Sets the start position of a tree node's range.
---@param node omi.fmt.ParseTreeNode
---@param start integer? The start position. If omitted, the current pointer is used.
---@protected
function Parser:setNodeStart(node, start)
    self:setNodeRange(node, start or self:pos())
end

---Sets the end position of a tree node's range.
---@param node omi.fmt.ParseTreeNode
---@param stop integer? The end position. If omitted, the current pointer is used.
---@protected
function Parser:setNodeEnd(node, stop)
    self:setNodeRange(node, nil, stop or self:pos())
end

---Reads an expression.
---Must be implemented by subclasses.
---@return omi.fmt.ParseTreeNode?
---@protected
function Parser:readExpression()
    error('not implemented')
end

---Reports a parser error.
---@param err string
---@param node omi.fmt.ParseTreeNode
---@param start integer?
---@param stop integer?
---@protected
function Parser:error(err, node, start, stop)
    self._errors[#self._errors + 1] = {
        message = err,
        node = node ~= self._tree and node or nil,
        range = {
            start or node.range[1],
            stop or node.range[2],
        },
    }

    if self._raiseErrors then
        error(err)
    end
end

---Reports a parser error at the current position.
---@param err string
---@param node omi.fmt.ParseTreeNode
---@param len integer?
---@protected
function Parser:errorHere(err, node, len)
    len = len or 1
    local pos = self:pos()
    self:error(err, node, pos, pos + len - 1)
end

---Reports a parser warning.
---@param err string
---@param node omi.fmt.ParseTreeNode
---@param start integer?
---@param stop integer?
---@protected
function Parser:warning(err, node, start, stop)
    self._warnings[#self._warnings + 1] = {
        message = err,
        node = node ~= self._tree and node or nil,
        range = {
            start or node.range[1],
            stop or node.range[2],
        },
    }
end

---Reports a parser warning at the current position.
---@param err string
---@param node omi.fmt.ParseTreeNode
---@param len integer?
---@protected
function Parser:warningHere(err, node, len)
    len = len or 1
    local pos = self:pos()
    self:warning(err, node, pos, pos + len - 1)
end

---Creates the parse tree.
---@protected
function Parser:createTree()
    local tree = self:addNode(self:createNode(self._treeNodeType))

    ---@cast tree omi.fmt.ParseTree
    tree.source = self._text
    self:setNodeEnd(tree, self:len())

    self._tree = tree
end

---Performs the parsing operation.
---@protected
function Parser:perform()
    while self:pos() <= self:len() do
        if not self:readExpression() then
            local pos = self:pos()
            self:error(string.format('unexpected character: `%s`', self:peek()), self._tree, pos, pos)

            -- avoid infinite loops
            self:forward()
        end
    end
end

---Performs postprocessing on the tree.
---@return omi.fmt.ParseTree
---@protected
function Parser:postprocess()
    return self._tree
end

---Resets the parser state.
---@param text string? If provided, sets the text to parse.
function Parser:reset(text)
    self._ptr = 1
    self._text = tostring(text or self._text or '')
    self._errors = {}
    self._warnings = {}
    self._node = nil
    self:createTree()
end

---Performs parsing and returns the tree.
---@return omi.fmt.ParseTree
function Parser:parse()
    self:perform()
    return self:postprocess()
end

---Creates a new parser.
---@param text string
---@param options omi.fmt.ParserOptions?
---@return omi.fmt.Parser
function Parser:new(text, options)
    ---@type omi.fmt.Parser
    local this = setmetatable({}, self)

    options = options or {}

    this._raiseErrors = utils.default(options.raiseErrors, false)
    this._treeNodeType = options.treeNodeType
    this:reset(text)

    return this
end


return Parser

end)
__bundle_register("interpolate/Libraries", function(require)
local utils = require("utils")
local MultiMap = require("interpolate/MultiMap")
local entry = require("interpolate/entry")
local unpack = unpack or table.unpack ---@diagnostic disable-line: deprecated
local select = select
local tostring = tostring
local tonumber = tonumber


---Built-in interpolator function libraries.
---@class omi.interpolate.Libraries
local libraries = {}

---Contains library function tables.
---@type table<string, table<string, fun(interpolator: omi.interpolate.Interpolator, ...: unknown): unknown?>>
libraries.functions = {}


local nan = tostring(0 / 0)


---Wrapper that converts the first argument to a string.
---@param f function
---@return function
local function firstToString(f)
    return function(_, ...)
        return f(tostring(select(1, ...) or ''), select(2, ...))
    end
end

---Wrapper for functions that expect a single string argument.
---Concatenates arguments into one argument.
---@param f function
---@return function
local function concatenateArgs(f)
    return function(_, ...)
        return f(utils.concat({ ... }))
    end
end

---Wrapper for comparator functions.
---@param f function
---@return function
local function comparator(f)
    return function(_, this, other)
        this = tostring(this or '')
        other = tostring(other or '')

        local nThis = tonumber(this)
        local nOther = tonumber(other)

        if nThis and nOther then
            return f(nThis, nOther)
        end

        return f(this, other)
    end
end

---Wrapper for unary math functions.
---@param f function
---@return function
local function unary(f)
    return function(_, ...)
        local value = tonumber(utils.concat({ ... }))
        if value then
            return f(value)
        end
    end
end

---Wrapper for unary math functions with multiple returns.
---@param f function
---@return function
local function unaryList(f)
    return function(self, ...)
        local value = tonumber(utils.concat({ ... }))
        if not value then
            return
        end

        return libraries.functions.map.list(self, f(value))
    end
end

---Wrapper for binary math functions.
---@param f function
---@return function
local function binary(f)
    return function(_, x, ...)
        x = tonumber(tostring(x))
        if not x then
            return
        end

        local y = tonumber(utils.concat({ ... }))
        if y then
            return f(x, y)
        end
    end
end

---Wrapper for pcall in interpolation functions.
---@param f function
---@param ... unknown
---@return ...
local function try(f, ...)
    local results = { pcall(f, ...) }
    if not results[1] then
        return
    end

    return unpack(results, 2)
end

---Wrapper for pcall in interpolation functions.
---Wraps return values as a list.
---@param f function
---@param interpolator omi.interpolate.Interpolator
---@param ... unknown
---@return omi.interpolate.MultiMap?
local function tryList(f, interpolator, ...)
    local results = { pcall(f, ...) }

    if not results[1] then
        return
    end

    return libraries.functions.map.list(interpolator, unpack(results, 2))
end


---Contains math functions.
libraries.functions.math = {
    pi = function() return math.pi end,
    isnan = function(_, n) return tostring(n) == nan end,
    abs = unary(math.abs),
    acos = unary(math.acos),
    add = binary(function(x, y) return x + y end),
    asin = unary(math.asin),
    atan = unary(math.atan),
    atan2 = binary(math.atan2),
    ceil = unary(math.ceil),
    cos = unary(math.cos),
    cosh = unary(math.cosh),
    deg = unary(math.deg),
    div = binary(function(x, y) return x / y end),
    exp = unary(math.exp),
    floor = unary(math.floor),
    fmod = binary(math.fmod),
    frexp = unaryList(math.frexp),
    int = unary(math.modf),
    ldexp = binary(math.ldexp),
    log = unary(function(x)
        return try(math.log, x)
    end),
    log10 = unary(function(x)
        return try(math.log10, x)
    end),
    max = function(_, ...)
        local max
        local strComp = not utils.all(tonumber, { ... })

        for i = 1, select('#', ...) do
            local arg = select(i, ...)
            arg = strComp and tostring(arg) or tonumber(arg)

            if not max or (arg and arg > max) then
                max = arg
            end
        end

        return max
    end,
    min = function(_, ...)
        local min
        local strComp = not utils.all(tonumber, { ... })

        for i = 1, select('#', ...) do
            local arg = select(i, ...)
            arg = strComp and tostring(arg) or tonumber(arg)

            if not min or (arg and arg < min) then
                min = arg
            end
        end

        return min
    end,
    mod = binary(function(x, y) return x % y end),
    modf = unaryList(math.modf),
    mul = binary(function(x, y) return x * y end),
    num = concatenateArgs(tonumber),
    pow = binary(math.pow),
    rad = unary(math.rad),
    sin = unary(math.sin),
    sinh = unary(math.sinh),
    subtract = binary(function(x, y) return x - y end),
    sqrt = unary(math.sqrt),
    tan = unary(math.tan),
    tanh = unary(math.tanh),
}

---Contains string functions.
libraries.functions.string = {
    str = concatenateArgs(tostring),
    lower = concatenateArgs(string.lower),
    upper = concatenateArgs(string.upper),
    reverse = concatenateArgs(string.reverse),
    trim = concatenateArgs(utils.trim),
    trimleft = concatenateArgs(utils.trimleft),
    trimright = concatenateArgs(utils.trimright),
    first = concatenateArgs(function(s) return s:sub(1, 1) end),
    last = concatenateArgs(function(s) return s:sub(-1) end),
    contains = firstToString(function(s, other) return utils.contains(s, tostring(other or '')) end),
    startswith = firstToString(function(s, other) return utils.startsWith(s, tostring(other or '')) end),
    endswith = firstToString(function(s, other) return utils.endsWith(s, tostring(other or '')) end),
    concat = function(_, ...) return utils.concat({ ... }) end,
    concats = firstToString(function(sep, ...) return utils.concat({ ... }, sep) end),
    len = function(_, ...) return #utils.concat({ ... }) end,
    capitalize = firstToString(function(s) return s:sub(1, 1):upper() .. s:sub(2) end),
    punctuate = firstToString(function(s, punctuation, chars)
        punctuation = tostring(punctuation or '.')
        chars = tostring(chars or '')

        local patt
        if chars ~= '' then
            patt = table.concat { '[', utils.escape(chars), ']$' }
        else
            patt = '%p$'
        end

        if not s:match(patt) then
            s = s .. punctuation
        end

        return s
    end),
    gsub = function(interpolator, s, pattern, repl, n)
        s = tostring(s or '')
        pattern = tostring(pattern or '')
        repl = tostring(repl or '')
        n = tonumber(n)
        return tryList(string.gsub, interpolator, s, pattern, repl, n)
    end,
    sub = firstToString(function(s, i, j)
        i = tonumber(i)
        if not i then
            return
        end

        j = tonumber(j)
        return j and s:sub(i, j) or s:sub(i)
    end),
    index = firstToString(function(s, i, d)
        i = tonumber(i)
        if i and i < 0 then
            i = #s + i + 1
        end

        if not i or i > #s or i < 1 then
            return d
        end

        return s:sub(i, i)
    end),
    match = function(interpolator, s, pattern, init)
        s = tostring(s or '')
        pattern = tostring(pattern or '')
        init = tonumber(init) or 1
        return tryList(string.match, interpolator, s, pattern, init)
    end,
    char = function(interpolator, ...)
        local args = {}

        local o = select(1, ...)
        if select('#', ...) == 1 and utils.isinstance(o, MultiMap) then
            ---@cast o omi.interpolate.MultiMap
            for _, value in o:pairs() do
                local num = tonumber(tostring(interpolator:convert(value)))
                if not num then
                    return
                end

                args[#args + 1] = num
            end

            return try(string.char, unpack(args))
        end

        for i = 1, select('#', ...) do
            local num = tonumber(tostring(interpolator:convert(select(i, ...))))
            if not num then
                return
            end

            args[#args + 1] = num
        end

        return try(string.char, unpack(args))
    end,
    byte = function(interpolator, s, i, j)
        i = tonumber(i or 1)
        if not i then
            return
        end

        j = tonumber(j or i)
        if not j then
            return
        end

        s = tostring(s or '')
        return tryList(string.byte, interpolator, s, i, j)
    end,
    rep = firstToString(function(s, n, sep)
        n = tonumber(n)
        if not n or n < 1 then
            return
        end

        return try(string.rep, s, n, tostring(sep or ''))
    end),
}

---Contains boolean functions.
libraries.functions.boolean = {
    ['not'] = function(interpolator, value)
        return not interpolator:toBoolean(value)
    end,
    eq = comparator(function(s, other) return s == other end),
    neq = comparator(function(s, other) return s ~= other end),
    gt = comparator(function(a, b) return a > b end),
    lt = comparator(function(a, b) return a < b end),
    gte = comparator(function(a, b) return a >= b end),
    lte = comparator(function(a, b) return a <= b end),
    any = function(interpolator, ...)
        for i = 1, select('#', ...) do
            local value = select(i, ...)
            if interpolator:toBoolean(value) then
                return value
            end
        end
    end,
    all = function(interpolator, ...)
        local n = select('#', ...)
        if n == 0 then
            return
        end

        for i = 1, n do
            if not interpolator:toBoolean(select(i, ...)) then
                return
            end
        end

        return select(n, ...)
    end,
    ['if'] = function(interpolator, condition, ...)
        if interpolator:toBoolean(condition) then
            return utils.concat({ ... })
        end
    end,
    unless = function(interpolator, condition, ...)
        if not interpolator:toBoolean(condition) then
            return utils.concat({ ... })
        end
    end,
    ifelse = function(interpolator, condition, yes, ...)
        if interpolator:toBoolean(condition) then
            return yes
        end

        return utils.concat({ ... })
    end,
}

---Contains functions related to translation.
libraries.functions.translation = {
    gettext = firstToString(function(...)
        if not getText then
            return ''
        end

        return getText(unpack(utils.pack(utils.map(tostring, { ... })), 1, 5))
    end),
    gettextornull = firstToString(function(...)
        if not getTextOrNull then
            return ''
        end

        return getTextOrNull(unpack(utils.pack(utils.map(tostring, { ... })), 1, 5))
    end),
}

---Contains functions related to at-maps.
libraries.functions.map = {
    ---Creates a list. If a single argument is provided and it is an at-map, its values will be used.
    ---Otherwise, the list is made up of all provided arguments.
    list = function(interpolator, ...)
        local entries = {}
        local o = select(1, ...)
        if not o then
            return
        end

        if select('#', ...) ~= 1 or not utils.isinstance(o, MultiMap) then
            for i = 1, select('#', ...) do
                o = interpolator:convert(select(i, ...))
                entries[#entries + 1] = entry(interpolator:convert(#entries + 1), o)
            end

            return MultiMap:new(entries)
        end

        ---@cast o omi.interpolate.MultiMap
        for _, value in o:pairs() do
            value = interpolator:convert(value)
            entries[#entries + 1] = entry(interpolator:convert(#entries + 1), value)
        end

        return MultiMap:new(entries)
    end,
    map = function(interpolator, func, o, ...)
        if not utils.isinstance(o, MultiMap) then
            return
        end

        local entries = {}

        ---@cast o omi.interpolate.MultiMap
        for key, value in o:pairs() do
            value = interpolator:convert(interpolator:execute(func, { value, ... }))
            entries[#entries + 1] = entry(key, value)
        end

        return MultiMap:new(entries)
    end,
    len = function(interpolator, ...)
        local o = select(1, ...)
        if select('#', ...) ~= 1 or not utils.isinstance(o, MultiMap) then
            return libraries.functions.string.len(interpolator, ...)
        end

        ---@cast o omi.interpolate.MultiMap
        return o:size()
    end,
    concat = function(interpolator, ...)
        local o = select(1, ...)
        if select('#', ...) ~= 1 or not utils.isinstance(o, MultiMap) then
            return libraries.functions.string.concat(interpolator, ...)
        end

        ---@cast o omi.interpolate.MultiMap
        return o:concat()
    end,
    concats = function(interpolator, sep, ...)
        local o = select(1, ...)
        if select('#', ...) ~= 1 or not utils.isinstance(o, MultiMap) then
            return libraries.functions.string.concats(interpolator, sep, ...)
        end

        ---@cast o omi.interpolate.MultiMap
        return o:concat(sep)
    end,
    nthvalue = function(_, o, n)
        if not o or not utils.isinstance(o, MultiMap) then
            return
        end

        n = tonumber(n)
        if not n then
            return
        end

        ---@cast o omi.interpolate.MultiMap
        local e = o:entry(n)
        if e then
            return e.value
        end
    end,
    first = function(interpolator, ...)
        local o = select(1, ...)
        if select('#', ...) ~= 1 or not utils.isinstance(o, MultiMap) then
            return libraries.functions.string.first(interpolator, ...)
        end

        ---@cast o omi.interpolate.MultiMap
        return o:first()
    end,
    last = function(interpolator, ...)
        local o = select(1, ...)
        if select('#', ...) ~= 1 or not utils.isinstance(o, MultiMap) then
            return libraries.functions.string.last(interpolator, ...)
        end

        ---@cast o omi.interpolate.MultiMap
        return o:last()
    end,
    has = function(_, o, k)
        if not o or not utils.isinstance(o, MultiMap) then
            return
        end

        return o:has(k)
    end,
    get = function(_, o, k, d)
        if not o or not utils.isinstance(o, MultiMap) then
            return
        end

        return o:get(k, d)
    end,
    index = function(interpolator, o, i, d)
        if not utils.isinstance(o, MultiMap) then
            return libraries.functions.string.index(interpolator, o, i, d)
        end

        ---@cast o omi.interpolate.MultiMap
        return o:index(i, d)
    end,
    unique = function(_, o)
        if utils.isinstance(o, MultiMap) then
            ---@cast o omi.interpolate.MultiMap
            return o:unique()
        end
    end,
}

---Contains functions that can mutate interpolator state.
libraries.functions.mutators = {
    randomseed = function(interpolator, seed)
        return interpolator:randomseed(seed)
    end,
    random = function(interpolator, m, n)
        if m and not tonumber(m) then
            return
        end

        if n and not tonumber(n) then
            return
        end

        return interpolator:random(m, n)
    end,
    ---Returns a random element from the given options.
    ---If the sole argument provided is an at-map, a value is chosen from its values.
    choose = function(interpolator, ...)
        local o = select(1, ...)
        if select('#', ...) ~= 1 or not utils.isinstance(o, MultiMap) then
            return interpolator:randomChoice({ ... })
        end

        ---@cast o omi.interpolate.MultiMap
        local values = {}
        for _, value in o:pairs() do
            values[#values + 1] = value
        end

        return interpolator:randomChoice(values)
    end,
    ---Sets the value of an interpolation token.
    set = function(interpolator, token, ...)
        local value
        if select('#', ...) > 1 then
            value = utils.concat({ ... })
        else
            value = select(1, ...)
        end

        return interpolator:setTokenValidated(tostring(token), value)
    end,
}


---List of interpolator libraries in the order they should be loaded.
libraries.list = {
    'math',
    'boolean',
    'string',
    'translation',
    'map',
    'mutators',
}


---Returns a table of interpolator functions.
---@param include table<string, true>? A set of function or modules to include.
---@param exclude table<string, true>? A set of function or modules to exclude.
---@return table
function libraries:load(include, exclude)
    exclude = exclude or {}

    local result = {}

    for i = 1, #self.list do
        local lib = self.list[i]
        if (not include or include[lib]) and not exclude[lib] then
            local funcs = libraries.functions[lib]
            for k, func in pairs(funcs) do
                local name = table.concat({ lib, '.', k })
                if (not include or include[name]) and not exclude[name] then
                    result[k] = func
                end
            end
        end
    end

    return result
end


return libraries

end)
__bundle_register("sandbox", function(require)
---@diagnostic disable: inject-field
local type = type
local rawget = rawget
local rawset = rawset
local setmetatable = setmetatable
local getSandboxOptions = getSandboxOptions


---Module containing functionality related to sandbox variables.
---@class omi.sandbox
local sandbox = {}

---Helper for retrieving custom sandbox options.
---@class omi.SandboxHelper
---@field protected _defaults table? Table containing default option values.
---@field protected _name string Name of a mod's sandbox variable table.
local SandboxHelper = {}


---Loads the default values for sandbox options.
function SandboxHelper:loadDefaults()
    if rawget(self, '_defaults') then
        return
    end

    local defaults = {}
    rawset(self, '_defaults', defaults)
    local options = getSandboxOptions()
    for i = 0, options:getNumOptions() - 1 do
        local opt = options:getOptionByIndex(i) ---@type unknown
        if opt:getTableName() == rawget(self, '_name') and opt.getDefaultValue then
            local name = opt:getShortName()
            defaults[name] = opt:getDefaultValue()
        end
    end
end

---Retrieves a sandbox option, or the default for that option.
---@param option string
---@return unknown?
function SandboxHelper:get(option)
    self:loadDefaults()

    local vars = SandboxVars[rawget(self, '_name')]
    local default = rawget(self, '_defaults')[option]
    if not vars or type(vars[option]) ~= type(default) then
        return default
    end

    return vars[option]
end

---Retrieves the default for a sandbox option.
---@param opt string
---@return unknown?
function SandboxHelper:getDefault(opt)
    self:loadDefaults()
    return rawget(self, '_defaults')[opt]
end


---Creates a new sandbox helper.
---@param tableName string The name of the sandbox options table.
---@return omi.SandboxHelper
function sandbox.new(tableName)
    return setmetatable({ _name = tableName }, SandboxHelper)
end


setmetatable(sandbox, {
    __call = function(self, ...) return self.new(...) end,
})


setmetatable(SandboxHelper, { __index = SandboxHelper.get })
sandbox.Sandbox = SandboxHelper


---@diagnostic disable-next-line: cast-type-mismatch
---@cast sandbox omi.sandbox | (fun(tableName: string): omi.SandboxHelper)
return sandbox

end)
---@class omi.Result<T>: { success: boolean, value: T?, error: string? }

---@class omi.lib
local OmiLib = {}

---@type omi.class | (fun(cls: table?): omi.Class)
OmiLib.class = require("class")

---@type omi.sandbox | (fun(tableName: string): omi.SandboxHelper)
OmiLib.sandbox = require("sandbox")

---@type omi.utils
OmiLib.utils = require("utils")

---@type omi.interpolate | (fun(text: string, tokens: table?, options: omi.interpolate.Options?): string)
OmiLib.interpolate = require("interpolate")

return OmiLib
