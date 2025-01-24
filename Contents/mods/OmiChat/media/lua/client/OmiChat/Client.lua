---Provides client API access to OmiChat.
---@class omichat.api.client
local API = require 'OmiChat/API/Client/Core'
API._commandStreams = require 'OmiChat/Definition/CommandStreams'
API._suggesters = require 'OmiChat/Definition/Suggesters'
API._transformers = require 'OmiChat/Definition/Transformers'

local StatusManager = require 'OmiChat/Component/StatusManager'


require 'OmiChat/API/Client/Chat'
require 'OmiChat/API/Client/Data'
require 'OmiChat/API/Client/Commands'
require 'OmiChat/API/Client/Extension'
require 'OmiChat/API/Client/Format'
require 'OmiChat/API/Client/Search'
require 'OmiChat/API/Client/Preferences'


Events.OnGameStart.Add(StatusManager.init)
Events.OnGameStart.Add(API._onGameStart)
Events.OnCreatePlayer.Add(API._onCreatePlayer)
Events.OnPlayerDeath.Add(API._onPlayerDeath)
Events.OnServerCommand.Add(API._onServerCommand)
Events.OnReceiveGlobalModData.Add(API._onReceiveGlobalModData)
Events.OnTick.Add(API._onTickTemporary)
API.Configuration:setOnSave(API._onConfigurationSave)


require 'OmiChat/Override/Chat'
return API
