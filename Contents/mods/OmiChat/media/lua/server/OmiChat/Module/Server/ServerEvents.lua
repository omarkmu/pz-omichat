---Server-side event handlers.

if isClient() then return end

local API = require 'OmiChat/Module/Server/Core' ---@class omichat.api.server

Events.SendCustomModData.Add(API.data.transmit)
