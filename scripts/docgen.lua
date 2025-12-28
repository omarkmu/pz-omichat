#!/usr/bin/env lua
---Helper for generating documentation from Fluent translation files.

local path = require 'path'
local cli = require 'cliargs'
local FluentBundle = require 'fluent'
local FTL = require 'fluent.messages'

local FTL_PATH = 'Contents/mods/OmiChat/common/media/ftl/OmiChat/en/'

local COLOR_TYPES = {
    -- commands
    ['0,1,0'] = 'code',

    -- highlight
    ['0,0.5,1'] = 'code',

    -- options
    ['0.7,0.7,0.7'] = 'italics',
}

---Terminates with an error.
local function quit(err, ...)
    local msg = err
    if select('#', ...) > 0 then
        msg = string.format(msg, ...)
    end

    print(string.format('%s: %s', cli.name, msg))
    os.exit(1)
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
            elseif value:is_a(FTL._InlineExpression) then
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

    -- `StringLiteral` cannot attach to `NamedArgument`
    local StringLiteral_mod = FTL.StringLiteral.__mod
    function FTL.StringLiteral:__mod(node)
        if node:is_a(FTL.NamedArgument) then
            node.value = self
            return node
        end

        return StringLiteral_mod(self, node)
    end

    -- `Term` cannot handle parameters
    local Term_format = FTL.TermReference.format
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

        return Term_format(self, parameters)
    end

    local CallArguments_mul = FTL.CallArguments.__mul
    function FTL.CallArguments:__mul(node)
        if node:is_a(FTL.TermReference) then
            node.arguments = self
            return node
        end

        return CallArguments_mul(self, node)
    end

    -- `set_parent` does not work for attributes
    -- this is heavy-handed, but it works
    local set_parent ---@type function
    set_parent = function(self, resource)
        if self.is_a then
            rawset(getmetatable(self), '_resource', resource)
        end

        for _, v in pairs(self) do
            if type(v) == 'table' then
                set_parent(v, resource)
            end
        end
    end

    for _, node in pairs(FTL) do
        if type(node) == 'table' then
            node.set_parent = set_parent
        end
    end
end

---Converts rich text into Markdown.
local function richTextToMarkdown(text)
    text = tostring(text):gsub('\n', ' ')

    text = text:gsub('%s*<PUSHRGB:(.-)>%s*(.-)%s*<POPRGB>%s*', function(color, inner)
        local convert = COLOR_TYPES[color] or 'code'
        if inner:find('`') then
            convert = 'italics'
        end

        if convert == 'code' then
            return string.format('`%s`', inner)
        end

        return string.format('*%s*', inner:gsub('%*', '\\*'))
    end)

    text = text
        :gsub('%s*<LINE>%s*', '  \n')
        :gsub('%s*<BR>%s*', '\n\n')
        :gsub('%s*<SPACE>%s*', ' ')

    return text
end

---Converts a key to be markdown-friendly.
local function convertKey(key, pattern)
    key = key:sub(1, 1) .. key:sub(2):gsub(pattern, function(letter)
        return '-' .. letter
    end)

    return key:lower()
end

---Converts a translation key into a Markdown filename.
local function getFilenameFromKey(key)
    return convertKey(key, '%u') .. '.md'
end

---Gets the description to use for an element.
local function getDescription(node)
    local tooltip = node:get_attribute('tooltip')
    local description = node:get_attribute('description')

    local desc
    if description then
        desc = tostring(description)
    elseif tooltip then
        desc = tostring(tooltip)
    end

    local descExtra = node:get_attribute('extra-description')
    if descExtra then
        desc = desc and (desc .. '<BR>') or ''
        desc = desc .. tostring(descExtra)
    end

    return desc and richTextToMarkdown(desc)
end

---Extracts configuration strings from Fluent translation files.
local function extractConfigData(bundle)
    local pages = { _map = {} }
    local resource = bundle:get_resource()

    for i = 1, #resource.body do
        local node = resource.body[i]

        local isMessage = node.type == 'Message'
        local id = isMessage and node.id.name
        local isConfig = id and id:find('^config%-%u') ~= nil

        if isConfig then
            local isTopLevel = id:find('^config%-[^%-]+$') ~= nil
            if isTopLevel then
                local title = node:get_attribute('title') or node

                local shortDesc = node:get_attribute('short-description')

                local key = id:match('^config%-(.+)')
                local element = {
                    key = key,
                    name = tostring(title),
                    description = getDescription(node),
                    shortDescription = shortDesc and richTextToMarkdown(tostring(shortDesc)),
                    _map = {},
                }

                pages._map[key] = element
                pages[#pages + 1] = element
            elseif not node:get_attribute('data-nodoc') then
                local current = pages[#pages] --[[@as any]]
                if not current then
                    quit('string defined before parent: %s', id)
                end

                local description = getDescription(node)
                if not description then
                    quit('no tooltip or description defined for message %s', id)
                end

                local keys = {} ---@type string[]

                -- config-X-Y-Z → [Y, Z]
                for key in id:gsub('^config%-[^%-]+', ''):gmatch('%-([^%-]+)') do
                    keys[#keys + 1] = key
                end

                local itemKey = keys[#keys]
                keys[#keys] = nil

                local element = {
                    key = itemKey,
                    name = node.value and tostring(node.value) or itemKey,
                    description = description,
                    _map = {},
                }

                local parent = current
                for j = 1, #keys do
                    local key = keys[j]
                    local target = parent._map[key]
                    if not target then
                        quit('string defined before parent: %s (missing %s)', id, key)
                    end

                    parent = target
                end

                parent._map[itemKey] = element
                parent[#parent + 1] = element
            end
        end
    end

    return pages
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

---Writes a string array to a file.
local function writeRope(filePath, rope)
    writeFile(filePath, table.concat(rope))
end

---Reads the contents of a file.
local function readFile(filePath)
    local file, err = io.open(filePath, 'r')
    if not file then
        return nil, err
    end

    local contents = file:read('*all')
    file:close()

    return contents
end

---Outputs configuration documentation to the specified directory.
local function outputConfigDocs(docsPath, pages)
    local function addToRope(element, rope, level, parentKey)
        local key = parentKey and (parentKey .. '.' .. element.key) or element.key
        if level > 1 then
            rope[#rope + 1] = '\n\n'
        end

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

        if level > 1 or element.description then
            rope[#rope + 1] = '\n'
        end

        if level > 1 then
            rope[#rope + 1] = '`'
            rope[#rope + 1] = key
            rope[#rope + 1] = '`  \n'
        end

        if element.description then
            rope[#rope + 1] = element.description
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

    for i = 1, #pages do
        local page = pages[i]
        local filename = getFilenameFromKey(page.key)

        local rope = addToRope(page, {}, 1)

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

        writeRope(path.abs(docsPath, 'configuration', filename), rope)
    end

    listRope[#listRope] = nil
    summaryRope[#summaryRope] = nil

    -- write the summary using the template
    local summary = readFile(path.abs(docsPath, 'SUMMARY_TEMPLATE.md'))
    summary = summary:gsub('{{configuration}}', table.concat(summaryRope))
    writeFile(path.abs(docsPath, 'SUMMARY.md'), summary)

    -- write _pages.md for including
    writeFile(path.abs(docsPath, 'configuration', '_pages.md'), table.concat(listRope))
end

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
    if not args and err then
        quit(err)
    end

    local termsPath = validatePath('file', args.root, FTL_PATH, 'shared.ftl')
    local configPath = validatePath('file', args.root, FTL_PATH, 'settings-main.ftl')
    local docsPath = validatePath('directory', args.root, 'docs')
    local templatePath = validatePath('file', docsPath, 'SUMMARY_TEMPLATE.md')

    local summary = readFile(templatePath)

    patchFluent()

    local bundle = FluentBundle()
    bundle:load_file(termsPath)
    bundle:load_file(configPath)

    local configPages = extractConfigData(bundle)
    outputConfigDocs(docsPath, configPages)
end

main()
