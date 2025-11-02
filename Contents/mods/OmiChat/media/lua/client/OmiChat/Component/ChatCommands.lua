---Command stream definitions.
---@namespace omichat

-- load early for `player.canUseAdminCommands`
require 'OmiChat/Module/Client/Player'

return {
    require 'OmiChat/Component/ChatCommand/Card',
    require 'OmiChat/Component/ChatCommand/Flip',
    require 'OmiChat/Component/ChatCommand/Roll',
    require 'OmiChat/Component/ChatCommand/Name',
    require 'OmiChat/Component/ChatCommand/Nickname',
    require 'OmiChat/Component/ChatCommand/Status',
    require 'OmiChat/Component/ChatCommand/ClearNames',
    require 'OmiChat/Component/ChatCommand/SetName',
    require 'OmiChat/Component/ChatCommand/IconInfo',
    require 'OmiChat/Component/ChatCommand/SetIcon',
    require 'OmiChat/Component/ChatCommand/ResetName',
    require 'OmiChat/Component/ChatCommand/ResetIcon',
    require 'OmiChat/Component/ChatCommand/AddLanguage',
    require 'OmiChat/Component/ChatCommand/ResetLanguages',
    require 'OmiChat/Component/ChatCommand/SetLanguageSlots',
    require 'OmiChat/Component/ChatCommand/Language',
    require 'OmiChat/Component/ChatCommand/Emote',
    require 'OmiChat/Component/ChatCommand/Clear',
    require 'OmiChat/Component/ChatCommand/Help',
}
