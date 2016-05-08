{_, SERVER_HOSTNAME} = window
Promise = require 'bluebird'
async = Promise.coroutine
dbg.extra('gameRequest')
{Grid, Input, Col, Row, Button} = ReactBootstrap
class GameRequest
  constructor: (@path, @body) ->
    Object.defineProperty @, 'ClickToCopy -->',
      get: ->
        require('electron').clipboard.writeText JSON.stringify @
        "Copied: #{@path}"

module.exports =
  reactClass: React.createClass
    getInitialState: ->
      enableGameReqDebug: dbg.extra('gameRequest').isEnabled()
      enableGameRepDebug: dbg.extra('gameResponse').isEnabled()
    componentDidMount: ->
      window.addEventListener 'game.request', @handleGameRequest
    componentWillUnmount: ->
      window.removeEventListener 'game.request', @handleGameRequest
    handleGameRequest: (e) ->
      {path, body} = e.detail
      if dbg.extra('gameRequest').isEnabled()
        dbg._getLogFunc()(new GameRequest(path, body))
    handleGameReqDebug: (e) ->
      {enableGameReqDebug} = @state
      if !enableGameReqDebug then dbg.h.gameRequest.enable() else dbg.h.gameRequest.disable()
      @setState
        enableGameReqDebug: !enableGameReqDebug
    handleGameRepDebug: (e) ->
      {enableGameRepDebug} = @state
      if !enableGameRepDebug then dbg.h.gameResponse.enable() else dbg.h.gameResponse.disable()
      @setState
        enableGameRepDebug: !enableGameRepDebug      
    render: ->
      <div className="form-group">
        <Grid>
          <Row>
            <Col xs={6}>
              <Button bsStyle={if @state?.enableGameReqDebug then 'success' else 'danger'} onClick={@handleGameReqDebug} style={width: '80%'}>
                 {if @state.enableGameReqDebug then '√ ' else ''}游戏请求日志
              </Button>
            </Col>
            <Col xs={6}>
              <Button bsStyle={if @state?.enableGameRepDebug then 'success' else 'danger'} onClick={@handleGameRepDebug} style={width: '80%'}>
                 {if @state.enableGameRepDebug then '√ ' else ''}游戏响应日志
              </Button>
            </Col>
          </Row>
        </Grid>
      </div>