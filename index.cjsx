{_, SERVER_HOSTNAME, APPDATA_PATH, toggleModal, React} = window
Promise = require 'bluebird'
path = require 'path-extra'
fs = Promise.promisifyAll require('fs-extra'), { multiArgs: true }
request = Promise.promisifyAll require('request'), { multiArgs: true }
async = Promise.coroutine
dbg.extra('gameRequest')
{Grid, Input, Col, Row, Button} = ReactBootstrap
Divider = require './views/divider'
FolderPickerConfig = require './views/folderpicker'
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
      start2Path: config.get("poi.dev.helper.start2Path", APPDATA_PATH)
    componentDidMount: ->
      window.addEventListener 'game.request', @handleGameRequest
    componentWillUnmount: ->
      window.removeEventListener 'game.request', @handleGameRequest
    handleGameRequest: (e) ->
      ((path) ->
        {path, body} = e.detail
        if dbg.extra('gameRequest').isEnabled()
          dbg._getLogFunc()(new GameRequest(path, body))
      )()
    handleGameReqDebug: (e) ->
      {enableGameReqDebug} = @state
      if !enableGameReqDebug
        dbg.enable()
        dbg.h.gameRequest.enable() 
      else
        dbg.h.gameRequest.disable()
      @setState
        enableGameReqDebug: !enableGameReqDebug
    handleGameRepDebug: (e) ->
      {enableGameRepDebug} = @state
      if !enableGameRepDebug
        dbg.enable()
        dbg.h.gameResponse.enable()
      else
        dbg.h.gameResponse.disable()
      @setState
        enableGameRepDebug: !enableGameRepDebug
    handleFolderPickerNewVal: (pathname) ->
      @setState
        start2Path: pathname
    handleSaveStart2: async (e) ->
      {start2Path} = @state
      console.log path
      savePath = path.join start2Path,'api_start2.json'
      err = yield fs.writeFileAsync savePath, localStorage.getItem('start2Body')
      console.error err if err
      toggleModal('保存 API START2', "保存至 #{savePath} 成功！") if not err
      toggleModal('保存 API START2', "保存至 #{savePath} 失败，请打开开发者工具检查错误信息。") if err
    testStart2Path: () ->
      {start2Path} = @state
      console.log start2Path
    render: ->
      <form style={padding: '0 10px'}>
        <div className="form-group">
          <Divider text={"调试日志"} />
          <Grid>
            <Row>
              <Col xs={6}>
                <Button bsStyle={if @state?.enableGameReqDebug then 'success' else 'danger'} onClick={@handleGameReqDebug} style={width: '100%'}>
                   {if @state.enableGameReqDebug then '√ ' else ''}游戏HTTP请求日志
                </Button>
              </Col>
              <Col xs={6}>
                <Button bsStyle={if @state?.enableGameRepDebug then 'success' else 'danger'} onClick={@handleGameRepDebug} style={width: '100%'}>
                   {if @state.enableGameRepDebug then '√ ' else ''}游戏HTTP响应日志
                </Button>
              </Col>
            </Row>
          </Grid>
        </div>
        <div className="form-group">
          <Divider text={"API START2"} />
          <Grid>
            <Row>
              <Col xs={6}>
                <FolderPickerConfig
                  label="本地保存目录"
                  configName="poi.dev.helper.start2Path"
                  defaultVal=APPDATA_PATH
                  onNewVal={@handleFolderPickerNewVal} />
              </Col>
              <Col xs={6}>
                <Button bsStyle={'success'} style={width: '100%'} onClick={@handleSaveStart2} style={width: '100%'}>
                  保存为本地文件
                </Button>
              </Col>
            </Row>
              <Col xs={6}>
                <Button ref="start2Path" bsStyle={'success'} style={width: '100%'} onClick={@testStart2Path} style={width: '100%'}>
                  上传到服务器
                </Button>
              </Col>
            <Row>
            </Row>
          </Grid>
        </div>
      </form>