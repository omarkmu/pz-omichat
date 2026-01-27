#!/usr/bin/env lua
---Helper for generating documentation from Fluent translation files.
---@namespace docgen

local path = require 'path'
local env = require 'path.env'
local cli = require 'cliargs'
local json = require 'cjson'
local FTL = require 'fluent.messages'
local FluentBundle = require 'fluent'

local concat = table.concat
local format = string.format

local DATA_PATH = 'Contents/mods/OmiChat/42.13/configuration.json'
local FTL_PATH = 'Contents/mods/OmiChat/common/media/ftl/OmiChat/en/'

local COLORS = {
    ['0,1,0'] = 'code',          -- commands
    ['0,0.5,1'] = 'code',        -- highlight
    ['0.7,0.7,0.7'] = 'italics', -- options
}

local LIST_TYPES = {
    ['tags'] = true,
    ['string-list'] = true,
    ['checkbox-group'] = true,
}

---Terminates with an error.
---@param err string
---@param ... any
local function quit(err, ...)
    local msg = err
    if select('#', ...) > 0 then
        msg = format(msg, ...)
    end

    if env.get('GITHUB_ACTIONS') == 'true' then
        msg = msg:sub(1, 1):upper() .. msg:sub(2)
        msg = format('::error::%s', msg)
    else
        msg = format('%s: %s', cli.name, msg)
    end

    print(msg)
    os.exit(1)
end

---Trims a string.
---@param s string
---@return string
local function trim(s)
    return (s:gsub('^%s*(.-)%s*$', '%1'))
end

---Fills in gaps in `fluent-lua`.
local function patchFluent()
    local class = require 'pl.class'
    local FluentNode = FTL.Message._base

    -- missing `Argument` class
    FTL.Argument = class(FluentNode)
    FTL.Argument._name = 'Argument'

    function FTL.Argument:__mul(node)
        if node:is_a(FTL.CallArguments) then
            local value = self.value
            if not value then
                return
            end

            if value:is_a(FTL.NamedArgument) then
                node.named[value.id.name] = value
                return node
            else
                node.positional[#node.positional + 1] = value
                return node
            end
        end
    end

    -- incomplete `NamedArgument` class
    function FTL.NamedArgument:format(parameters)
        return self.value:format(parameters)
    end

    function FTL.NamedArgument:__mod(node)
        if node:is_a(FTL.Argument) then
            node.value = self
            return node
        end
    end

    -- `StringLiteral` cannot attach to `NamedArgument`/`Argument`
    local StringLiteral_mod = FTL.StringLiteral.__mod
    function FTL.StringLiteral:__mod(node)
        if node:is_a(FTL.NamedArgument) or node:is_a(FTL.Argument) then
            node.value = self
            return node
        end

        return StringLiteral_mod(self, node)
    end

    -- `TermReference` cannot handle parameters
    local TermReference_format = FTL.TermReference.format
    function FTL.TermReference:format(parameters)
        if self.arguments and self.arguments.named then
            local params_copy = {}
            for k in pairs(parameters) do
                params_copy[k] = parameters[k]
            end

            for k, v in pairs(self.arguments.named) do
                params_copy[k] = v:format(parameters)
            end

            parameters = params_copy
        end

        return TermReference_format(self, parameters)
    end

    local CallArguments_mul = FTL.CallArguments.__mul
    function FTL.CallArguments:__mul(node)
        if node:is_a(FTL.TermReference) then
            node.arguments = self
            return node
        end

        return CallArguments_mul(self, node)
    end

    -- `get_parent` and `set_parent` set the parent on the class instead of the instance
    -- also, `set_parent` does not work for attributes
    local function get_parent(self)
        return self._resource
    end

    local function set_parent(self, resource)
        if self._name == 'MessageReference' or self._name == 'TermReference' then
            rawset(self, '_resource', resource)
        end

        for k, v in pairs(self) do
            if k ~= '_resource' and type(v) == 'table' then
                set_parent(v, resource)
            end
        end
    end

    for _, node in pairs(FTL) do
        if type(node) == 'table' then
            node.get_parent = get_parent
            node.set_parent = set_parent
        end
    end
end

---Converts rich text into Markdown.
---@param text any
---@return string
local function richTextToMarkdown(text)
    text = tostring(text):gsub('\n', ' ')

    text = text:gsub('%s*<PUSHRGB:(.-)>%s*(.-)%s*<POPRGB>%s*', function(color, inner)
        local convert = COLORS[color] or 'code'
        if inner:find('`') then
            convert = 'italics'
        end

        if convert == 'code' then
            return format('`%s`', inner)
        end

        return format('*%s*', inner:gsub('%*', '\\*'))
    end)

    text = text
        :gsub('%s*<LINE>%s*', '  \n')
        :gsub('%s*<BR>%s*', '\n\n')
        :gsub('%s*<SPACE>%s*', ' ')

    return text
end

---Converts a key to be markdown-friendly.
---@param key string
---@param pattern string
local function convertKey(key, pattern)
    key = key:sub(1, 1) .. key:sub(2):gsub(pattern, function(letter)
        return '-' .. letter
    end)

    return key:lower()
end

---Gets the description to use for an element.
local function getDescription(data, contentNode, vars)
    local tooltip = contentNode:get_attribute('tooltip')

    local desc ---@type string?
    if data._description then
        desc = tostring(data._description)
        local var = desc:match('^%$([%u_]+)$')
        if var then
            desc = vars[var]
        end
    elseif tooltip then
        desc = richTextToMarkdown(tostring(tooltip))
    end

    if data._extraDescription then
        desc = desc and (desc .. '\n\n') or ''

        local extraDesc = tostring(data._extraDescription)
        local var = extraDesc:match('^%$([%u_]+)$')
        if var then
            extraDesc = vars[var]
        end

        desc = desc .. extraDesc
    end

    return desc
end

---Extracts translations for a configuration option's available values.
---@return table<string, string>, table<string, string>
local function extractConfigOptionData(node, _type)
    local names = {}
    local descriptions = {}

    if not node.attributes then
        return names, descriptions
    end

    for i = 1, #node.attributes do
        local attr = node.attributes[i]
        local key = attr.id.name
        if key:sub(1, 15) == 'option-tooltip-' then
            local name = key:sub(16)
            descriptions[name] = tostring(attr.value)
        elseif key:sub(1, 7) == 'option-' then
            local name = key:sub(8)
            names[name] = tostring(attr.value)
        end
    end

    return names, descriptions
end

---Processes raw configuration data and extracts configuration strings from Fluent translation files.
---@param configData any The configuration data table.
---@param contentBundle any The bundle containing English translations.
---@return table[]
local function processConfigData(configData, contentBundle)
    local pages = {}
    local vars = configData._VARS

    local function processField(data, idPrefix)
        local isTopLevel = idPrefix == nil
        local skip = data._noDoc or data.hidden
        local id = (idPrefix or 'config-') .. data.name

        local content = contentBundle:get_message(id)
        if not content then
            quit('missing translation for %s', id)
        end

        if not data.type then
            quit('missing type for %s', id)
        elseif type(data.type) ~= 'string' then
            quit('invalid type for %s', id)
        end

        local element
        if isTopLevel and not skip then
            local title = content:get_attribute('title') or content.value
            if not title then
                quit('no title or value for top-level %s', id)
            end

            element = {
                key = data.name,
                skipKey = data._noDocKey,
                name = tostring(title),
                type = data.type,
                description = getDescription(data, content, vars),
                shortDescription = data._shortDescription,
            }
        elseif not skip then
            local optionNames, optionDescs = extractConfigOptionData(content)

            element = {
                key = data.name,
                type = data.type,
                skipKey = data._noDocKey,
                name = content.value and tostring(content.value) or data.name,
                description = getDescription(data, content, vars),
                max = data.max,
                min = data.min,
                default = data.default,
                options = data.options,
                optionNames = optionNames,
                optionDescriptions = optionDescs,
                defaultAll = data.defaultAll,
            }

            if not element.description then
                quit('no tooltip or description defined for %s', id)
            end

            if element.max and not tonumber(element.max) then
                quit('invalid max value for %s (%s)', id, element.max)
            end

            if element.min and not tonumber(element.min) then
                quit('invalid min value for %s (%s)', id, element.min)
            end
        end

        if element and data.fields then
            for i = 1, #data.fields do
                element[#element + 1] = processField(data.fields[i], id .. '-')
            end
        end

        return element
    end

    for i = 1, #configData.fields do
        pages[#pages + 1] = processField(configData.fields[i])
    end

    return pages --[[@as any]]
end

---Writes a string to a file.
local function writeFile(filePath, content)
    local file, err = io.open(filePath, 'w')
    if not file then
        quit('failed to write file %s: %s', filePath, err) ---@cast file -?
    end

    file:write(content)
    file:close()
end

---Reads the contents of a file.
---@param filePath string
---@return string
local function readFile(filePath)
    local file, err = io.open(filePath, 'r')
    if not file then
        quit('failed to read file %s: %s', filePath, err)
    end

    ---@cast file -?
    local contents = file:read('*all')
    file:close()

    return contents
end

---Generates documentation for configuration.
---@param configData table The configuration data table.
---@param contentBundle any The bundle containing English translations.
---@return GeneratedConfigurationData
local function generateFromConfig(configData, contentBundle)
    local pages = processConfigData(configData, contentBundle)

    ---Writes a list of options to a rope.
    ---@param list string[]
    ---@param rope string[]
    ---@param optNames table<string, string>
    ---@param optDescs table<string, string>
    local function writeOptList(list, rope, optNames, optDescs)
        for i = 1, #list do
            local value = list[i]
            local name = optNames[value]
            local desc = optDescs[value]
            rope[#rope + 1] = '\n- `'
            rope[#rope + 1] = name or value
            rope[#rope + 1] = '`'

            if name and name ~= value then
                rope[#rope + 1] = ' (`'
                rope[#rope + 1] = value
                rope[#rope + 1] = '`)'
            end

            if desc then
                rope[#rope + 1] = ': '
                rope[#rope + 1] = desc
            end
        end
    end

    ---Adds data from an element to a string list.
    ---@param element table
    ---@param rope string[]
    ---@param level integer
    ---@param parentKey string?
    local function addToRope(element, rope, level, parentKey)
        local _type = element.type or '?'
        local key = parentKey and (parentKey .. '.' .. element.key) or element.key
        if level > 1 then
            rope[#rope + 1] = '\n\n'
        end

        local optNames = element.optionNames
        local optDescs = element.optionDescriptions

        local anchor = convertKey(key, '%.(%u)')
        if level > 1 then
            anchor = anchor:match('^.-%-(.+)$') or anchor
        end

        rope[#rope + 1] = ('#'):rep(level)
        rope[#rope + 1] = ' '
        rope[#rope + 1] = element.name
        rope[#rope + 1] = ' {#'
        rope[#rope + 1] = anchor
        rope[#rope + 1] = '}'

        if level > 1 and not element.skipKey then
            rope[#rope + 1] = '\n`'
            rope[#rope + 1] = key
            rope[#rope + 1] = '`  \n'
        elseif element.description then
            rope[#rope + 1] = '\n'
        end

        local defaultValue
        if _type == 'format-string' then
            defaultValue = element.default or '$Default()'
        elseif not LIST_TYPES[_type] and _type ~= 'string-map' then
            defaultValue = element.default
        end

        local addedExtra = false
        if element.defaultAll then
            rope[#rope + 1] = '**Default**: all  \n'
            addedExtra = true
        elseif defaultValue ~= nil then
            rope[#rope + 1] = '**Default**: `'

            if element.type == 'color' then
                local color = concat(defaultValue, ',')
                rope[#rope + 1] = color
                rope[#rope + 1] = '`'
                rope[#rope + 1] = ' <span style="--color-display: rgb('
                rope[#rope + 1] = color
                rope[#rope + 1] = ')"></span>'
            else
                local str = tostring(defaultValue)
                rope[#rope + 1] = optNames[str] or str
                rope[#rope + 1] = '`'
            end

            rope[#rope + 1] = '  \n'
            addedExtra = true
        end

        if element.min then
            rope[#rope + 1] = '**Minimum**: `'
            rope[#rope + 1] = element.min
            rope[#rope + 1] = '`  \n'
            addedExtra = true
        end

        if element.max then
            rope[#rope + 1] = '**Maximum**: `'
            rope[#rope + 1] = element.max
            rope[#rope + 1] = '`  \n'
            addedExtra = true
        end

        if addedExtra then
            rope[#rope + 1] = '\n'
        end

        if element.description then
            rope[#rope + 1] = element.description
        end

        local isDropdown = _type == 'dropdown'
        local supportsLists = LIST_TYPES[_type] or isDropdown
        local addListExtras = (element.default and not defaultValue) or element.options
        if supportsLists and addListExtras then
            rope[#rope + 1] = '\n'

            local options = element.options
            local defaults = element.default

            if defaults and not defaultValue and not isDropdown then
                rope[#rope + 1] = #defaults == 1 and '\n**Default**:' or '\n**Defaults**:'
                writeOptList(defaults, rope, optNames, optDescs)
                rope[#rope + 1] = '\n'
            end

            if options then
                rope[#rope + 1] = '\n**Options**:'
                writeOptList(options, rope, optNames, optDescs)

                rope[#rope + 1] = '\n'
            end
        elseif _type == 'string-map' then
            local defaults = element.default or {}
            local defaultList = {} ---@type table[]

            for k, v in pairs(defaults) do
                defaultList[#defaultList + 1] = { k, v }
            end

            table.sort(defaultList, function(a, b)
                return a[1] < b[1]
            end)

            if #defaultList ~= 0 then
                rope[#rope + 1] = #defaultList == 1 and '\n\n**Default**:' or '\n\n**Defaults**:'
            end

            for i = 1, #defaultList do
                local pair = defaultList[i]

                rope[#rope + 1] = '\n- `'
                rope[#rope + 1] = pair[1]
                rope[#rope + 1] = '` =  `'
                rope[#rope + 1] = pair[2]
                rope[#rope + 1] = '`'
            end
        end

        for i = 1, #element do
            addToRope(element[i], rope, level + 1, key)
        end

        if level == 1 then
            rope[#rope + 1] = '\n'
        end

        return rope
    end

    ---@type string[]
    local listRope = {}

    ---@type string[]
    local summaryRope = {
        '- [Configuration](configuration/index.md)\n',
    }

    local pageContents = {}
    for i = 1, #pages do
        local page = pages[i]
        local filename = convertKey(page.key, '%u') .. '.md'

        local rope = addToRope(page, {}, 1)
        pageContents[filename] = concat(rope)

        summaryRope[#summaryRope + 1] = '    - ['
        summaryRope[#summaryRope + 1] = page.name
        summaryRope[#summaryRope + 1] = '](configuration/'
        summaryRope[#summaryRope + 1] = filename
        summaryRope[#summaryRope + 1] = ')'
        summaryRope[#summaryRope + 1] = '\n'

        listRope[#listRope + 1] = '- ['
        listRope[#listRope + 1] = page.name
        listRope[#listRope + 1] = '](./'
        listRope[#listRope + 1] = filename
        listRope[#listRope + 1] = ')'

        if page.shortDescription then
            listRope[#listRope + 1] = ': '
            listRope[#listRope + 1] = page.shortDescription
        end

        listRope[#listRope + 1] = '\n'
    end

    listRope[#listRope] = nil
    summaryRope[#summaryRope] = nil

    return {
        summary = concat(summaryRope),
        list = concat(listRope),
        subpages = pageContents,
    }
end

---Generates a list of languages for which the mod provides translations.
---@param contentBundle any The bundle containing English translations.
---@return string
local function generateLanguageList(contentBundle)
    local rope = {}
    local languages = {}
    local resource = contentBundle:get_resource()
    for i = 1, #resource.body do
        local msg = resource.body[i]

        local isMessage = msg.type == 'Message'
        local id = isMessage and msg.id.name

        if id and id:match('^language%-(.+)') then
            languages[#languages + 1] = tostring(msg)
        end
    end

    table.sort(languages)

    for i = 1, #languages do
        rope[#rope + 1] = '- '
        rope[#rope + 1] = languages[i]
        rope[#rope + 1] = '\n'
    end

    rope[#rope] = nil

    return concat(rope)
end

---Validates that a path is of the expected type.
---@param expected 'file' | 'directory'
---@param ... string
---@return string
local function validatePath(expected, ...)
    local absPath = path.abs(...)
    local isValid = expected == 'file' and path.isfile or path.isdir

    if not isValid(absPath) then
        quit('path is not a %s: %s', expected, absPath)
    end

    return absPath
end

local function main()
    cli:set_name('docgen')
    cli:option('--root=DIRECTORY', 'path to the root directory', path.cwd())

    local args, err = cli:parse(arg)
    if err then
        quit(err)
    elseif not args then
        quit('Failed to parse arguments')
    end

    local root = args.root
    local dataJson = readFile(validatePath('file', root, DATA_PATH))
    local termsPath = validatePath('file', root, FTL_PATH, 'shared.ftl')
    local mainPath = validatePath('file', root, FTL_PATH, 'main.ftl')
    local configPath = validatePath('file', root, FTL_PATH, 'configuration-main.ftl')

    local docsPath = validatePath('directory', root, 'docs')
    local summary = readFile(validatePath('file', docsPath, 'SUMMARY_TEMPLATE.md'))

    patchFluent()

    local data = json.decode(dataJson)

    local contentBundle = FluentBundle()
    contentBundle:load_file(termsPath)
    contentBundle:load_file(configPath)
    contentBundle:load_file(mainPath)

    local config = generateFromConfig(data, contentBundle)
    local languages = generateLanguageList(contentBundle)

    -- write the summary using the template
    summary = summary:gsub('{{configuration}}', config.summary)
    writeFile(path.abs(docsPath, 'SUMMARY.md'), summary)

    -- write configuration/_pages.md (page list for configuration index)
    writeFile(path.abs(docsPath, 'configuration', '_pages.md'), config.list)

    -- write customization/_languages.md (translated language name list)
    writeFile(path.abs(docsPath, 'customization', '_languages.md'), languages)

    -- write configuration subpages
    for filename, contents in pairs(config.subpages) do
        writeFile(path.abs(docsPath, 'configuration', filename), contents)
    end
end

local success, err = pcall(main)
if not success then
    quit(err or 'an error occurred')
end

--#region Type Definitions

---@class GeneratedConfigurationData
---@field summary string The string to inject into SUMMARY.md.
---@field list string The string to inject into configuration/_pages.md.
---@field subpages table<string, string> Associates configuration subpage names to file contents.

--#endregion
