local lib = require 'OmiChat/lib'
local split = string.split

---@class omichat.DelimitedList : omi.Class
---@field private _cached string
---@field private _delimiter string
---@field private _list string[]
local DelimitedList = lib.class()


---Updates the underlying string for the delimited list.
---If the string is the same, this has no effect.
---@param str string
---@return string[] list
function DelimitedList:update(str)
    str = str:trim()
    if str == self._cached then
        return self._list
    end

    local list = self._list
    table.wipe(list)

    local elements = split(str, self._delimiter)
    for i = 1, #elements do
        local el = elements[i]:trim()
        if el ~= '' then
            list[#list + 1] = el
        end
    end

    return list
end

---Returns the underlying list.
---@return string[]
function DelimitedList:list()
    return self._list
end

---Creates a new delimited list.
---@param str string?
---@param delimiter string?
---@return omichat.DelimitedList
function DelimitedList:new(str, delimiter)
    local this = setmetatable({}, self)

    this._cached = ''
    this._list = {}
    this._delimiter = delimiter or ';'

    if str then
        this:update(str)
    end

    return this
end


return DelimitedList
