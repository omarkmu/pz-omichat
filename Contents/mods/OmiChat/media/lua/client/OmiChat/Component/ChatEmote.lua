---Handler for emote macros.
---@namespace omichat

local utils = require 'OmiChat/Utils'

---@class ChatEmote : omi.Class
---@field emote? string The emote to play using `IsoPlayer.playEmote`.
---@field protected _onPlay? fun(player: IsoPlayer, emote: string) A callback function to handle playing the emote.
---@field protected _isEnabled? fun(): boolean Callback for determining whether the emote should be usable.
local ChatEmote = utils.lib.class()


---Checks whether the emote is enabled.
---@return boolean enabled
function ChatEmote:isEnabled()
    if not self._isEnabled then
        return true
    end

    return self:_isEnabled()
end

---Plays the emote.
---@param player IsoPlayer The player to play the emote on.
---@param emoteName string The name of the emote to play.
function ChatEmote:play(player, emoteName)
    if self._onPlay then
        self._onPlay(player, emoteName)
    elseif self.emote then
        player:playEmote(self.emote)
    end
end

---Creates a new chat emote handler.
---@param args Args.ChatEmote Arguments for the emote handler, or an emote name.
---@return ChatEmote
function ChatEmote:new(args)
    ---@type ChatEmote
    local this = setmetatable({}, self)

    this.emote = args.emote
    this._onPlay = args.onPlay
    this._isEnabled = args.isEnabled

    return this
end

return ChatEmote

--#region Type Definitions

---@class Args.ChatEmote
---@field emote? string The emote to play using `IsoPlayer.playEmote`.
---@field onPlay? fun(player: IsoPlayer, emote: string) A callback function to handle playing the emote.
---@field isEnabled? fun(self: ChatEmote): boolean Callback for determining whether the emote should be usable.

--#endregion
