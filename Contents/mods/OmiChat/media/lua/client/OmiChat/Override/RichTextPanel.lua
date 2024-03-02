---Handles overrides for rich text panels.
require 'ISUI/ISRichTextPanel'

local max = math.max
local concat = table.concat
local trim = string.trim
local getTexture = getTexture
local utils = require 'OmiChat/util'


---@class omichat.ISRichTextPanel : ISRichTextPanel
local ISRichTextPanel = ISRichTextPanel

local _processCommand = ISRichTextPanel.processCommand


---Adds a line of text to the rich text panel.
---@param self ISRichTextPanel
---@param text string
---@param x number
---@param y number
---@param lineImageHeight number
---@param curLine number
---@param maxLineWidth number
---@return number x
---@return number y
---@return number lineImageHeight
---@return number curLine
local function addText(self, text, x, y, lineImageHeight, curLine, maxLineWidth)
    local textManager = getTextManager()
    local chunkText = self.lines[curLine] or ''
    local chunkX = self.lineX[curLine] or x

    text = utils.unescapeRichText(text:trim())
    if chunkText == '' then
        chunkText = text
    elseif text ~= '' then
        chunkText = concat { chunkText, ' ', text }
    end

    local font = textManager:getFontFromEnum(self.font)
    local pixLen = font:getWidth(chunkText)
    if chunkX + pixLen > maxLineWidth then
        if self.lines[curLine] and self.lines[curLine] ~= '' then
            curLine = curLine + 1
        end

        x = 0
        y = y + max(lineImageHeight, font:getLineHeight())
        lineImageHeight = 0
        self.lines[curLine] = text
        if self.lines[curLine] ~= '' then
            x = self.indent
        end

        self.lineX[curLine] = x
        self.lineY[curLine] = y
        x = x + font:getWidth(self.lines[curLine])
    else
        if not self.lines[curLine] then
            self.lineX[curLine] = x
            self.lineY[curLine] = y
        end

        self.lines[curLine] = chunkText
        if self.lineX[curLine] == 0 and self.lines[curLine] ~= '' then
            self.lineX[curLine] = self.indent
        end

        x = self.lineX[curLine] + pixLen
    end

    return x, y, lineImageHeight, curLine
end

---Adds an image to the rich text panel.
---@param self ISRichTextPanel
---@param texture Texture
---@param x number
---@param y number
---@param w number
---@param h number
---@param lineImageHeight number
---@param lineHeight number
---@param center boolean
---@return boolean success
---@return number x
---@return number y
---@return number lineImageHeight
local function addImage(self, texture, x, y, w, h, lineImageHeight, lineHeight, center)
    if not texture then
        return false, x, y, lineImageHeight
    end

    self.images[self.imageCount] = texture
    if w == 0 then
        w = texture:getWidth()
        h = texture:getHeight()
    end

    if x + w >= self.width - (self.marginLeft + self.marginRight) then
        x = 0
        y = y + lineHeight
    end

    if center and lineImageHeight < h / 2 + 8 then
        lineImageHeight = h / 2 + 16
    elseif not center and lineImageHeight < h then
        lineImageHeight = h
    end

    self.imageY[self.imageCount] = y
    self.imageW[self.imageCount] = w
    self.imageH[self.imageCount] = h

    if center then
        local mx = (self.width - self.marginLeft - self.marginRight) / 2 - self.marginLeft
        self.imageX[self.imageCount] = mx - (w / 2)

        for i = 1, #self.lines do
            if self.lineY[i] == y then
                self.lineY[i] = self.lineY[i] + (h / 2)
            end
        end

        y = y + h / 2
    else
        self.imageX[self.imageCount] = x + 2
    end

    self.imageCount = self.imageCount + 1
    x = x + w + 7

    return true, x, y, lineImageHeight
end

---Reads the image, width, and height from an image command.
---@param command string
---@return string command
---@return number x
---@return number y
local function readImageCommand(command)
    local w = 0
    local h = 0
    if command:find(',') then
        local pieces = command:split(',')

        command = pieces[1]:trim()
        w = tonumber(trim(pieces[2] or '')) or 0
        h = tonumber(trim(pieces[3] or '')) or w
    end

    local endPos = command:find(':') or 0
    return command:sub(endPos + 1), w, h
end


---Override to allow commands without a leading space.
function ISRichTextPanel:paginate()
    self.textDirty = false
    self.imageCount = 1
    self.font = self.defaultFont
    self.fonts = {}
    self.images = {}
    self.imageX = {}
    self.imageY = {}
    self.rgb = {}
    self.rgbCurrent = { r = 1, g = 1, b = 1 }
    self.rgbStack = {}
    self.orient = {}
    self.indent = 0
    self.imageW = {}
    self.imageH = {}
    self.lineY = {}
    self.lineX = {}
    self.lines = {}
    self.keybinds = {}

    local text = (self:replaceKeyNames(self.text) .. ' '):gsub('\n', ' <LINE> ')
    if self.maxLines > 0 then
        local textLines = text:split('<LINE>')
        local start = max(1, #textLines - self.maxLines + 1)
        local lines = { unpack(textLines, start) }

        local parts = { ' ' }
        for i = 1, #lines do
            parts[#parts + 1] = lines[i]
            parts[#parts + 1] = ' <LINE> '
        end

        text = concat(parts)
    end

    local x = 0
    local y = 0
    local ptr = 1
    local curLine = 1
    local lineImageHeight = 0
    local textManager = getTextManager()
    local maxLineWidth = self.maxLineWidth or (self.width - self.marginRight - self.marginLeft)

    while ptr <= #text do
        local specialPos = text:find('[< ]', ptr)
        if not specialPos then
            break
        end

        local special = text:sub(specialPos, specialPos)
        local commandEndPos = special == '<' and text:find('>', specialPos + 1)
        local nextSpace = text:find(' ', specialPos + 1)
        if commandEndPos and nextSpace < commandEndPos then
            -- space within the angle brackets → don't interpret as command
            commandEndPos = nil
            specialPos = nextSpace
        end

        if commandEndPos then
            -- handle text before command
            local current = text:sub(ptr, specialPos - 1):trim()
            if current ~= '' then
                x, y, lineImageHeight, curLine = addText(self, current, x, y, lineImageHeight, curLine, maxLineWidth)
            end

            -- handle command
            if not self.lines[curLine] then
                self.lines[curLine] = ''
                self.lineX[curLine] = x
                self.lineY[curLine] = y
            end

            curLine = curLine + 1

            local lineHeight = max(10, lineImageHeight, textManager:getFontFromEnum(self.font):getLineHeight())
            local command = text:sub(specialPos + 1, commandEndPos - 1)

            self.currentLine = curLine
            x, y, lineImageHeight = self:processCommand(command, x, y, lineImageHeight, lineHeight)

            ptr = commandEndPos + 1
        else
            -- add text up to and including the special character
            local current = text:sub(ptr, specialPos):trim()
            x, y, lineImageHeight, curLine = addText(self, current, x, y, lineImageHeight, curLine, maxLineWidth)

            ptr = specialPos + 1
        end
    end

    local lineHeight = textManager:getFontFromEnum(self.font):getLineHeight()
    text = text:sub(ptr):trim()
    if text ~= '' then
        self.lines[curLine] = utils.unescapeRichText(text)
        if x == 0 and self.lines[curLine] ~= '' then
            x = self.indent
        end

        self.lineX[curLine] = x
        self.lineY[curLine] = y
        y = y + lineHeight
    elseif self.lines[curLine] and self.lines[curLine] ~= '' then
        y = y + max(lineHeight, lineImageHeight)
    end

    if self.autosetheight then
        self:setHeight(self.marginTop + y + self.marginBottom)
    end

    self:setScrollHeight(self.marginTop + y + self.marginBottom)
end

---Override to improve input handling safety.
---@param command string
---@param x number
---@param y number
---@param lineImageHeight number
---@param lineHeight number
---@return number
---@return number
---@return number
function ISRichTextPanel:processCommand(command, x, y, lineImageHeight, lineHeight)
    if command:find('PUSHRGB:') then
        self.rgbStack[#self.rgbStack + 1] = self.rgbCurrent
        local rgb = command:sub(9, #command):split(',')
        self.rgb[self.currentLine] = {}
        self.rgb[self.currentLine].r = tonumber(rgb[1]) or 255
        self.rgb[self.currentLine].g = tonumber(rgb[2]) or 255
        self.rgb[self.currentLine].b = tonumber(rgb[3]) or 255
        self.rgbCurrent = self.rgb[self.currentLine]
        return x, y, lineImageHeight
    end

    if command:find('RGB:') then
        local rgb = command:sub(5, #command):split(',')
        self.rgb[self.currentLine] = {}
        self.rgb[self.currentLine].r = tonumber(rgb[1]) or 255
        self.rgb[self.currentLine].g = tonumber(rgb[2]) or 255
        self.rgb[self.currentLine].b = tonumber(rgb[3]) or 255
        self.rgbCurrent = self.rgb[self.currentLine]
        return x, y, lineImageHeight
    end

    local success, image, w, h
    if command:find('IMAGE:') then
        image, w, h = readImageCommand(command)
        success, x, y, lineImageHeight = addImage(self, getTexture(image), x, y, w, h, lineImageHeight, lineHeight, false)
    end

    if command:find('IMAGECENTRE:') then
        image, w, h = readImageCommand(command)
        success, x, y, lineImageHeight = addImage(self, getTexture(image), x, y, w, h, lineImageHeight, lineHeight, true)
    end

    if command:find('JOYPAD:') then
        image, w, h = readImageCommand(command)
        local texture = Joypad.Texture[image]
        success, x, y, lineImageHeight = addImage(self, texture, x, y, w, h, lineImageHeight, lineHeight, false)
    end

    if success then
        return x, y, lineImageHeight
    elseif success == false then
        utils.logError('unknown texture used in image command: `%s`', image)
        return x, y, lineImageHeight
    end

    if command:find('INDENT:') then
        self.indent = tonumber(command:sub(8)) or 0
        return x, y, lineImageHeight
    end

    if command:find('SETX:') then
        x = tonumber(command:sub(6)) or 0
        return x, y, lineImageHeight
    end

    return _processCommand(self, command, x, y, lineImageHeight, lineHeight)
end
