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

---Gets a MultiMap of entries associated with a key.
---@param key unknown The key to query.
---@param default unknown? A default value to return if there is no nth value.
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


---@diagnostic disable-next-line: param-type-mismatch
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


local submodules = {
    require("utils/string"),
    require("utils/table"),
    require("utils/type"),
}

for _, mod in ipairs(submodules) do
    for k, v in pairs(mod) do
        utils[k] = v
    end
end


return utils

end)
__bundle_register("utils/type", function(require)
local deepEquals
local rawget = rawget
local getmetatable = getmetatable
local unpack = unpack or table.unpack


---Utilities related to types.
---@class omi.utils.type
local utils = {}


---Checks two values for deep equality.
---@param t1 unknown
---@param t2 unknown
---@param seen table<table, boolean>
deepEquals = function(t1, t2, seen)
    if t1 == t2 then
        return true
    end

    if type(t1) ~= 'table' or type(t1) ~= type(t2) then
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
    local nArgs = select('#', ... )
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
---@generic T
---@param value? `T`
---@param default T
---@return T
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
---@generic T
---@param predicate fun(arg: T): unknown Predicate function.
---@param target table<unknown, T> | (fun(...): T) Key-value iterator function or table.
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
---@generic T
---@param predicate fun(arg: T): unknown Predicate function.
---@param target table<unknown, T> | (fun(...): T) Key-value iterator function or table.
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
---@generic T
---@param predicate fun(value: T): unknown Predicate function.
---@param target table<unknown, T> | (fun(...): T) Key-value iterator function or table.
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
---@generic K
---@generic T
---@generic U
---@param func fun(value: T, key: K): U Map function.
---@param target table | (fun(...): T) Key-value iterator function or table.
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
---@generic T
---@generic K
---@generic U
---@param func fun(value: T, key: K, index: integer): U Map function.
---@param target T[] | (fun(...): T) Key-value iterator function or list.
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
---@generic K
---@generic T
---@param iter fun(...): K, T Key-value iterator function.
---@param ... unknown Iterator state.
---@return table<K, T>
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
---@generic K
---@generic T
---@generic U
---@param acc fun(result: U, element: T, key: K): U Reducer function.
---@param initial U? Initial value.
---@param target table | (fun(...): K, T) Key-value iterator function or table.
---@param ... unknown Iterator state.
---@return U
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
---@generic K
---@generic T
---@generic U
---@param acc fun(result: U, element: T, key: K): U Reducer function.
---@param initial U? Initial value.
---@param target table | (fun(...): K, T) Key-value iterator function or list.
---@param ... unknown Iterator state.
---@return U
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


---Tests if a table is empty or has only keys from 1 to #t.
---@param t table
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
            result[#result+1] = ','
            result[#result+1] = space
        end

        isFirst = false

        result[#result+1] = tab

        if not isNumeric then
            result[#result+1] = '['
            if type(k) == 'table' then
                -- don't show table keys
                result[#result+1] = '{...}'
            else
                result[#result+1] = stringifyPrimitive(k)
            end

            result[#result+1] = keyEnd
        end

        if type(v) == 'table' then
            result[#result+1] = stringifyTable(v, seen, pretty, depth + 1, maxDepth)
        else
            result[#result+1] = stringifyPrimitive(v)
        end
    end

    result[#result+1] = pretty and (space .. string.rep('    ', depth - 1)) or space
    result[#result+1] = '}'

    return table.concat(result)
end

---Returns text that's safe for use in a pattern.
---@param text string
---@return string
function utils.escape(text)
    return (text:gsub('([[%]%+-*?().^$])', '%%%1'))
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
    return (text:gsub('^%s*(.+)', '%1'))
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

    return text:sub(-#other) == other
end

---Stringifies a value for display.
---For non-tables, this is equivalent to `tostring.`
---Tables will stringify their values unless a `__tostring` method is present on their metatable.
---@param value unknown
---@param pretty boolean? If true, tables will include newlines and tabs.
---@param maxDepth number? Maximum table depth. Defaults to 5.
function utils.stringify(value, pretty, maxDepth)
    if type(value) ~= 'table' then
        return tostring(value)
    end

    return stringifyTable(value, {}, pretty, 1, maxDepth)
end


return utils

end)
__bundle_register("interpolate/Interpolator", function(require)
local table = table
local unpack = unpack or table.unpack
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
---@field protected _requireCustomTokenUnderscore boolean
---@field protected _parser omi.interpolate.Parser
---@field protected _rand Random?
local Interpolator = class()

---@type omi.interpolate.Libraries
Interpolator.Libraries = InterpolatorLibraries

---@class omi.interpolate.Options
---@field pattern string? The initial format string of the interpolator.
---@field allowTokens boolean? Whether tokens should be interpreted. If false, tokens will be treated as text.
---@field allowMultiMaps boolean? Whether at-maps should be interpreted. If false, they are ignored.
---@field allowFunctions boolean? Whether functions should be interpreted. If false, they are ignored.
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
    for _, child in ipairs(nodes) do
        self:evaluateNode(child, parts)
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
    for _, e in ipairs(node.entries) do
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

    for i, argument in ipairs(node.args) do
        local parts = {}

        for _, child in ipairs(argument) do
            self:evaluateNode(child, parts)
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
    for _, node in ipairs(self._built) do
        self:evaluateNode(node, parts)
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
    if self._requireCustomTokenUnderscore and not utils.startsWith(token, '_') and self._tokens[token] == nil then
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

    self._built = self._parser:postprocess(self._parser:parse())
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
        allowAtExpressions = self._allowMultiMaps
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

---Parser for the interpolated string format.
---@class omi.interpolate.Parser : omi.fmt.Parser
---@field protected _allowTokens boolean
---@field protected _allowAtExpr boolean
---@field protected _allowFunctions boolean
local InterpolationParser = BaseParser:derive()


---@class omi.interpolate.ParserOptions : omi.fmt.ParserOptions
---@field allowTokens boolean?
---@field allowFunctions boolean?
---@field allowAtExpressions boolean?


---@enum omi.interpolate.NodeType
InterpolationParser.NodeType = {
    tree = 'tree',
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

InterpolationParser.Errors = {
    BAD_CHAR = BaseParser.Errors.BAD_CHAR,
    WARN_UNTERM_FUNC = 'potentially unterminated function `%s`',
    UNTERM_FUNC = 'unterminated function `%s`',
    UNTERM_AT = 'unterminated at-expression',
}

local ERR = InterpolationParser.Errors
local NodeType = InterpolationParser.NodeType


---@class omi.interpolate.ValueNode
---@field type omi.interpolate.NodeType
---@field value string

---@alias omi.interpolate.Argument omi.interpolate.ValueNode[]

---@class omi.interpolate.CallNode : omi.interpolate.ValueNode
---@field args omi.interpolate.Node[][]

---@class omi.interpolate.AtExpressionEntry
---@field key omi.interpolate.ValueNode[]
---@field value omi.interpolate.ValueNode[]

---@class omi.interpolate.AtExpressionNode
---@field type omi.interpolate.NodeType
---@field entries omi.interpolate.AtExpressionEntry[]

---@alias omi.interpolate.Node
---| omi.interpolate.ValueNode
---| omi.interpolate.CallNode
---| omi.interpolate.AtExpressionNode

-- text patterns for node types
local TEXT_PATTERNS = {
    -- $ = token/escape/call start, space = delimiter, ( = string start, ) = call end
    [NodeType.argument] = '^([^ $()]+)[ $()]?',
    -- $ = token/escape/call start, @ = at-expression start, ; = delim, : = delimiter, ( = string start, ) = expression end
    [NodeType.at_key] = '^([^:;$@()]+)[:;$@()]?',
    [NodeType.at_value] = '^([^:;$@()]+)[:;$@()]?',
    -- $ = escape start, ) = string end
    [NodeType.string] = '^([^$)]+)[$)]?',
}

local SPECIAL = {
    ['$'] = true,
    ['@'] = true,
    [':'] = true,
    [';'] = true,
    ['('] = true,
    [')'] = true,
}

---Returns a table with consecutive text nodes merged.
---@param tab omi.fmt.ParseTreeNode[]
---@return omi.fmt.ParseTreeNode[]
local function mergeTextNodes(tab)
    local result = {}

    local last
    for _, node in ipairs(tab) do
        if node.type == NodeType.text then
            if last and last.parts and last.type == NodeType.text then
                last.parts[#last.parts + 1] = node.value
            else
                last = {
                    type = NodeType.text,
                    parts = { node.value }
                }

                result[#result + 1] = last
            end
        else
            result[#result + 1] = node
            last = node
        end
    end

    for _, node in ipairs(result) do
        if node.parts and node.type == NodeType.text then
            node.value = table.concat(node.parts)
            node.parts = nil
        end
    end

    return result
end

local postprocessNode
postprocessNode = function(node)
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
            for _, child in ipairs(node.children) do
                local built = postprocessNode(child)
                if built and built.value then
                    parts[#parts + 1] = built.value
                end
            end
        end

        return {
            type = NodeType.text,
            value = table.concat(parts)
        }
    elseif nodeType == NodeType.argument or nodeType == NodeType.at_key or nodeType == NodeType.at_value then
        -- convert node to list of child nodes
        local parts = {}
        if node.children then
            for _, child in ipairs(node.children) do
                local built = postprocessNode(child)
                if built then
                    parts[#parts + 1] = built
                end
            end
        end

        return mergeTextNodes(parts)
    elseif nodeType == NodeType.call then
        local args = {}

        if node.children then
            for _, child in ipairs(node.children) do
                local type = child.type
                if type == NodeType.argument then
                    args[#args + 1] = postprocessNode(child)
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
            local builtKey = key and key.type == NodeType.at_key and postprocessNode(key)

            if builtKey then
                local value = children[i + 1]
                local builtValue = value and value.type == NodeType.at_value and postprocessNode(value)

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


---Gets the pattern for text nodes given the current node type.
---@return string
---@protected
function InterpolationParser:getTextPattern()
    local type = self._node and self._node.type

    if TEXT_PATTERNS[type] then
        return TEXT_PATTERNS[type]
    end

    -- $ = token/escape/call start, @ = at-expression start
    return '^([^$@]+)[$@]?'
end

---Reads space characters and returns a literal string of spaces.
---@return string?
---@protected
function InterpolationParser:readSpaces()
    local spaces = self._text:match('^( +)', self:pos())
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
    local value = self._text:match('^$([$@();:])', self:pos())
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
    local value = self._text:match(self:getTextPattern(), self:pos())
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

    local name, pos = self._text:match('^$([%w_]+)()', self:pos())

    if not name then
        return
    end

    local node = self:createNode(NodeType.token, { value = name })
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

    local name, start = self._text:match('^$([%w_]+)%(()', self:pos())
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

    local start = self._text:match('^@%(()', self:pos())
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
        or self:readText()
        or self:readSpecialText()
end

---Performs postprocessing on a result tree.
---@param tree omi.fmt.ParseTree
---@return omi.interpolate.Node[]
function InterpolationParser:postprocess(tree)
    local result = {}
    if tree.errors or not tree.children then
        return result
    end

    for _, child in ipairs(tree.children) do
        local built = postprocessNode(child)
        if built then
            result[#result + 1] = built
        end
    end

    return mergeTextNodes(result)
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
---@field protected _errors omi.fmt.ParserError[]?
---@field protected _warnings omi.fmt.ParserError[]?
---@field protected _ptr integer
---@field protected _text string
---@field protected _node omi.fmt.ParseTreeNode?
---@field protected _tree omi.fmt.ParseTree
---@field protected _treeNodeName string
---@field protected _raiseErrors boolean
local Parser = class()

Parser.Errors = {
    BAD_CHAR = 'unexpected character: `%s`'
}


---Base parser options.
---@class omi.fmt.ParserOptions
---@field raiseErrors boolean?
---@field treeNodeName string?

---Describes error that occurred during parsing.
---@class omi.fmt.ParserError
---@field error string
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
---@field errors omi.fmt.ParserError[]?
---@field warnings omi.fmt.ParserError[]?


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
    local len = #self._text
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
        error = err,
        node = node ~= self._tree and node or nil,
        range = {
            start or node.range[1],
            stop or node.range[2]
        }
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
        error = err,
        node = node ~= self._tree and node or nil,
        range = {
            start or node.range[1],
            stop or node.range[2]
        }
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

---Resets the parser state.
---@param text string? If provided, sets the text to parse.
function Parser:reset(text)
    self._ptr = 1
    self._text = tostring(text or self._text or '')
    self._errors = {}
    self._warnings = {}
    self._node = nil

    local tree = self:addNode(self:createNode(self._treeNodeName))

    ---@cast tree omi.fmt.ParseTree
    tree.source = self._text
    self:setNodeEnd(tree, #self._text)

    self._tree = tree
end

---Performs parsing and returns the tree.
---@return omi.fmt.ParseTree
function Parser:parse()
    while self:pos() <= self:len() do
        if not self:readExpression() then
            self:error(Parser.Errors.BAD_CHAR:format(self:peek()), self._tree, self:pos(), self:pos())

            -- avoid infinite loops
            self:forward()
        end
    end

    if #self._errors > 0 then
        self._tree.errors = self._errors
    end

    if #self._warnings > 0 then
        self._tree.warnings = self._warnings
    end

    return self._tree
end

---Performs postprocessing on the result tree, transforming it into a usable format.
---@param tree omi.fmt.ParseTree
---@return unknown
function Parser:postprocess(tree)
    return tree
end

---Creates a new parser.
---@param text string
---@param options omi.fmt.ParserOptions?
---@return omi.fmt.Parser
function Parser:new(text, options)
    ---@type omi.fmt.Parser
    local this = setmetatable({}, self)

    options = options or {}

    this:reset(text)
    this._raiseErrors = utils.default(options.raiseErrors, false)
    this._treeNodeName = utils.default(options.treeNodeName, 'tree')

    return this
end


return Parser

end)
__bundle_register("interpolate/Libraries", function(require)
local utils = require("utils")
local MultiMap = require("interpolate/MultiMap")
local entry = require("interpolate/entry")
local unpack = unpack or table.unpack
local select = select
local tostring = tostring
local tonumber = tonumber


---Built-in interpolator function libraries.
---@class omi.interpolate.Libraries
local InterpolatorLibraries = {}

local functions = {}
local nan = tostring(0/0)


---Wrapper that converts the first argument to a string.
---@param f function
---@return function
local function firstToString(f)
    return function(self, ...)
        return f(tostring(select(1, ...) or ''), select(2, ...))
    end
end

---Wrapper for functions that expect a single string argument.
---Concatenates arguments into one argument.
---@param f function
---@return function
local function concatenateArgs(f)
    return function(self, ...)
        return f(utils.concat({ ... }))
    end
end

---Wrapper for comparator functions.
---@param f function
---@return function
local function comparator(f)
    return function(self, this, other)
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
local function unary(f)
    return function(self, ...)
        local value = tonumber(utils.concat({ ... }))
        if value then
            return f(value)
        end
    end
end

---Wrapper for unary math functions with multiple returns.
---@param f function
local function unaryList(f)
    return function(self, ...)
        local value = tonumber(utils.concat({ ... }))
        if not value then
            return
        end

        return functions.map.list(self, f(value))
    end
end

---Wrapper for binary math functions.
---@param f function
local function binary(f)
    return function(self, x, ...)
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
---@return unknown?
local function tryList(f, interpolator, ...)
    local results = { pcall(f, ...) }

    if not results[1] then
        return
    end

    return functions.map.list(interpolator, unpack(results, 2))
end


---Contains math functions.
functions.math = {
    pi = function() return math.pi end,
    ---@param interpolator omi.interpolate.Interpolator
    isnan = function(interpolator, n) return tostring(n) == nan end,
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
    ---@param interpolator omi.interpolate.Interpolator
    max = function(interpolator, ...)
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
    ---@param interpolator omi.interpolate.Interpolator
    min = function(interpolator, ...)
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
functions.string = {
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
    ---@param interpolator omi.interpolate.Interpolator
    concat = function(interpolator, ...) return utils.concat({ ... }) end,
    concats = firstToString(function(sep, ...) return utils.concat({ ... }, sep) end),
    ---@param interpolator omi.interpolate.Interpolator
    len = function(interpolator, ...) return #utils.concat({ ... }) end,
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
    ---@param interpolator omi.interpolate.Interpolator
    gsub = function(interpolator, s, pattern, repl, n)
        s = tostring(s or '')

        if not pattern or pattern == '' then
            return functions.map.list(interpolator, s, #s + 1)
        end

        return tryList(string.gsub, interpolator, s, pattern or '', repl or '', n)
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
    ---@param interpolator omi.interpolate.Interpolator
    match = function(interpolator, s, pattern, init)
        if not pattern then
            return
        end

        s = tostring(s or '')
        return tryList(string.match, interpolator, s, pattern, init or 1)
    end,
    ---@param interpolator omi.interpolate.Interpolator
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
    ---@param interpolator omi.interpolate.Interpolator
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
functions.boolean = {
    ---@param interpolator omi.interpolate.Interpolator
    ['not'] = function(interpolator, value)
        return not interpolator:toBoolean(value)
    end,
    eq = comparator(function(s, other) return s == other end),
    neq = comparator(function(s, other) return s ~= other end),
    gt = comparator(function(a, b) return a > b end),
    lt = comparator(function(a, b) return a < b end),
    gte = comparator(function(a, b) return a >= b end),
    lte = comparator(function(a, b) return a <= b end),
    ---@param interpolator omi.interpolate.Interpolator
    any = function(interpolator, ...)
        for i = 1, select('#', ...) do
            local value = select(i, ...)
            if interpolator:toBoolean(value) then
                return value
            end
        end
    end,
    ---@param interpolator omi.interpolate.Interpolator
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
    ---@param interpolator omi.interpolate.Interpolator
    ['if'] = function(interpolator, condition, ...)
        if interpolator:toBoolean(condition) then
            return utils.concat({ ... })
        end
    end,
    ---@param interpolator omi.interpolate.Interpolator
    unless = function(interpolator, condition, ...)
        if not interpolator:toBoolean(condition) then
            return utils.concat({ ... })
        end
    end,
    ---@param interpolator omi.interpolate.Interpolator
    ifelse = function(interpolator, condition, yes, ...)
        if interpolator:toBoolean(condition) then
            return yes
        end

        return utils.concat({ ... })
    end,
}

---Contains functions related to translation.
functions.translation = {
    gettext = firstToString(function(...)
        if not getText then return '' end
        return getText(unpack(utils.pack(utils.map(tostring, { ... })), 1, 5))
    end),
    gettextornull = firstToString(function(...)
        if not getTextOrNull then return '' end
        return getTextOrNull(unpack(utils.pack(utils.map(tostring, { ... })), 1, 5))
    end),
}

---Contains functions related to at-maps.
functions.map = {
    ---Creates a list. If a single argument is provided and it is an at-map, its values will be used.
    ---Otherwise, the list is made up of all provided arguments.
    ---@param interpolator omi.interpolate.Interpolator
    ---@param ... unknown
    ---@return omi.interpolate.MultiMap?
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
    ---@param interpolator omi.interpolate.Interpolator
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
    ---@param interpolator omi.interpolate.Interpolator
    len = function(interpolator, ...)
        local o = select(1, ...)
        if select('#', ...) ~= 1 or not utils.isinstance(o, MultiMap) then
            return functions.string.len(interpolator, ...)
        end

        ---@cast o omi.interpolate.MultiMap
        return o:size()
    end,
    ---@param interpolator omi.interpolate.Interpolator
    concat = function(interpolator, ...)
        local o = select(1, ...)
        if select('#', ...) ~= 1 or not utils.isinstance(o, MultiMap) then
            return functions.string.concat(interpolator, ...)
        end

        ---@cast o omi.interpolate.MultiMap
        return o:concat()
    end,
    ---@param interpolator omi.interpolate.Interpolator
    concats = function(interpolator, sep, ...)
        local o = select(1, ...)
        if select('#', ...) ~= 1 or not utils.isinstance(o, MultiMap) then
            return functions.string.concats(interpolator, sep, ...)
        end

        ---@cast o omi.interpolate.MultiMap
        return o:concat(sep)
    end,
    ---@param interpolator omi.interpolate.Interpolator
    nthvalue = function(interpolator, o, n)
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
    ---@param interpolator omi.interpolate.Interpolator
    first = function(interpolator, ...)
        local o = select(1, ...)
        if select('#', ...) ~= 1 or not utils.isinstance(o, MultiMap) then
            return functions.string.first(interpolator, ...)
        end

        ---@cast o omi.interpolate.MultiMap
        return o:first()
    end,
    ---@param interpolator omi.interpolate.Interpolator
    last = function(interpolator, ...)
        local o = select(1, ...)
        if select('#', ...) ~= 1 or not utils.isinstance(o, MultiMap) then
            return functions.string.last(interpolator, ...)
        end

        ---@cast o omi.interpolate.MultiMap
        return o:last()
    end,
    ---@param interpolator omi.interpolate.Interpolator
    index = function(interpolator, o, i, d)
        if not utils.isinstance(o, MultiMap) then
            return functions.string.index(interpolator, o, i, d)
        end

        ---@cast o omi.interpolate.MultiMap
        return o:index(i, d)
    end,
    ---@param interpolator omi.interpolate.Interpolator
    unique = function(interpolator, o)
        if utils.isinstance(o, MultiMap) then
            ---@cast o omi.interpolate.MultiMap
            return o:unique()
        end
    end,
}

---Contains functions that can mutate interpolator state.
functions.mutators = {
    ---Sets the random seed for the interpolator.
    ---@param interpolator omi.interpolate.Interpolator
    ---@param seed unknown
    randomseed = function(interpolator, seed)
        return interpolator:randomseed(seed)
    end,
    ---Returns a random number.
    ---@param interpolator omi.interpolate.Interpolator
    ---@param m integer?
    ---@param n integer?
    ---@return number?
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
    ---@param interpolator omi.interpolate.Interpolator
    ---@param ... unknown
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
    ---@param interpolator omi.interpolate.Interpolator
    ---@param token unknown
    ---@param ... unknown
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

---Contains library function tables.
InterpolatorLibraries.functions = functions

---List of interpolator libraries in the order they should be loaded.
InterpolatorLibraries.list = {
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
function InterpolatorLibraries:load(include, exclude)
    exclude = exclude or {}

    local result = {}

    for _, lib in ipairs(self.list) do
        if (not include or include[lib]) and not exclude[lib] then
            local funcs = InterpolatorLibraries.functions[lib]
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


return InterpolatorLibraries

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
---@class omi.Sandbox
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
---@return omi.Sandbox
function sandbox.new(tableName)
    return setmetatable({ _name = tableName }, SandboxHelper)
end


---@diagnostic disable-next-line: param-type-mismatch
setmetatable(sandbox, {
    __call = function(self, ...) return self.new(...) end,
})


setmetatable(SandboxHelper, { __index = SandboxHelper.get })
sandbox.Sandbox = SandboxHelper


---@diagnostic disable-next-line: cast-type-mismatch
---@cast sandbox omi.sandbox | (fun(tableName: string): omi.Sandbox)
return sandbox

end)
---@class omi.Result<T>: { success: boolean, value: T?, error: string? }

---@class omi.lib
local OmiLib = {}

OmiLib.VERSION = '1.0.0'

---@type omi.class | (fun(cls: table?): omi.Class)
OmiLib.class = require("class")

---@type omi.sandbox | (fun(tableName: string): omi.Sandbox)
OmiLib.sandbox = require("sandbox")

---@type omi.utils
OmiLib.utils = require("utils")

---@type omi.interpolate | (fun(text: string, tokens: table?, options: omi.interpolate.Options?): string)
OmiLib.interpolate = require("interpolate")

return OmiLib
