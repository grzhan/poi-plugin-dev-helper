{_, SERVER_HOSTNAME} = window
Promise = require 'bluebird'
async = Promise.coroutine
class GameResponse
  constructor: (@path, @body) ->
    Object.defineProperty @, 'ClickToCopy -->',
      get: ->
        require('electron').clipboard.writeText JSON.stringify @
        "Copied: #{@path}"
handleGameRequest = (e) ->
  {path, body} = e.detail
  if dbg.extra('gameRequest').isEnabled()
    dbg._getLogFunc()(new GameResponse(resPath, body))

module.exports =
  pluginDidLoad: (e) ->
    window.addEventListener 'game.request', handleGameRequest
  pluginWillUnload: (e) ->
    window.removeEventListener 'game.request', handleGameRequest
  show: false
