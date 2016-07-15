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
HOST = 'api.kcwiki.moe'
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
      uploadAuthPassword: localStorage.getItem('devHelperUploadPassword')
      uploading: false
      mapArea: 0
      mapInfo: 0
      cellId: 0
      nextCell: ''
      cellUploading: false
      isSortie: false
    componentDidMount: ->
      window.addEventListener 'game.request', @handleGameRequest
      window.addEventListener 'game.response', @handleGameResponse
    componentWillUnmount: ->
      window.removeEventListener 'game.request', @handleGameRequest
      window.removeEventListener 'game.response', @handleGameResponse
    handleGameRequest: (e) ->
      ((path) ->
        {path, body} = e.detail
        if dbg.extra('gameRequest').isEnabled()
          dbg._getLogFunc()(new GameRequest(path, body))
      )()
    handleGameResponse: (e) ->
      that = @
      ((path) ->
        {path, body} = e.detail
        switch path
          when '/kcsapi/api_start2'
            localStorage.setItem('start2Body', JSON.stringify(body))
          when '/kcsapi/api_req_map/start'
            {mapArea, mapInfo, cellId, isSortie} = that.state
            that.setState
              isSortie: true
              mapArea: body.api_maparea_id
              mapInfo: body.api_mapinfo_no
              cellId: body.api_no
          when '/kcsapi/api_req_map/next'
            {mapArea, mapInfo, cellId, isSortie} = that.state
            that.setState
              isSortie: true
              mapArea: body.api_maparea_id
              mapInfo: body.api_mapinfo_no
              cellId: body.api_no
          when '/kcsapi/api_port/port'
            {isSortie} = that.state
            that.setState
              isSortie: false
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
      savePath = path.join start2Path,'api_start2.json'
      err = yield fs.writeFileAsync savePath, localStorage.getItem('start2Body')
      console.error err if err
      toggleModal('保存 API START2', "保存至 #{savePath} 成功！") if not err
      toggleModal('保存 API START2', "保存至 #{savePath} 失败，请打开开发者工具检查错误信息。") if err
    handleSetPassword: (e) ->
      {uploadAuthPassword} = @state
      uploadAuthPassword = @refs.uploadAuthPassword.getValue()
      localStorage.setItem 'devHelperUploadPassword', uploadAuthPassword
      @setState
        uploadAuthPassword: uploadAuthPassword
    handleUploadStart2: async (e) ->
      {uploadAuthPassword, uploading} = @state
      return if uploading
      @setState
        uploading: true
      response = yield request.postAsync "http://#{HOST}/start2/upload",
        form: 
          password: uploadAuthPassword
          data: localStorage.getItem('start2Body')
      repData = if response instanceof Array then response[1] else response.body
      @setState
        uploading: false
      try
        rep = JSON.parse(repData) if repData
      catch err
        if err instanceof Error
          console.error "#{err.name}: #{err.message}\n#{err.stack}"
        else
          console.error err
        console.log repData
        toggleModal('上传 API START2', "保存至 api.kcwiki.moe 失败，请打开开发者工具检查错误信息。")
        @setState
          cellUploading: false
        return
      if rep?.result is 'success'
        toggleModal('上传 API START2', "上传至 api.kcwiki.moe 成功！")
      else
        console.error rep?.reason
        toggleModal('上传 API START2', "保存至 api.kcwiki.moe 失败，请打开开发者工具检查错误信息。")
    handleSetNextCell: (e) ->
      {nextCell} = @state
      nextCell = @refs.nextCell.getValue()
      @setState
        nextCell: nextCell
    handleUploadMapCell: async (e) ->
      {nextCell, cellUploading, mapArea, mapInfo, cellId} = @state
      return if cellUploading
      @setState
        cellUploading: true
      response = yield request.postAsync "http://#{HOST}/map/cell",
        form:
          mapArea: mapArea
          mapInfo: mapInfo
          cellNo: nextCell
          cellId: cellId
      repData = if response instanceof Array then response[1] else response.body
      try
        rep = JSON.parse(repData) if repData
      catch err
        if err instanceof Error
          console.error "#{err.name}: #{err.message}\n#{err.stack}"
        else
          console.error err
        console.log repData
        toggleModal('上传 Map Cell ID', "保存至 api.kcwiki.moe 失败，请打开开发者工具检查错误信息。")
        @setState
          cellUploading: false
        return
      if rep?.result is 'success'
        toggleModal('上传 Map Cell ID', "上传至 api.kcwiki.moe 成功！")
      else
        console.error rep?.reason
        toggleModal('上传 Map Cell ID', "保存至 api.kcwiki.moe 失败，请打开开发者工具检查错误信息。")
      @setState
        cellUploading: false
    selectInput: (id) ->
      document.getElementById(id).select()
    render: ->
      <form style={padding: '0 10px'}>
        <div className="form-group">
          <Divider text={"调试日志"} />
          <Grid>
            <Row>
              <Col lg={6} md={12} style={marginTop: 10}>
                <Button bsStyle={if @state?.enableGameReqDebug then 'success' else 'danger'} onClick={@handleGameReqDebug} style={width: '100%'}>
                   {if @state.enableGameReqDebug then '√ ' else ''}游戏HTTP请求日志
                </Button>
              </Col>
              <Col lg={6} md={12} style={marginTop: 10}>
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
              <Col lg={6} md={12} style={marginTop: 10}>
                <FolderPickerConfig
                  label="本地保存目录"
                  configName="poi.dev.helper.start2Path"
                  defaultVal=APPDATA_PATH
                  onNewVal={@handleFolderPickerNewVal} />
              </Col>
              <Col lg={6} md={12} style={marginTop: 10}>
                <Button bsStyle={'success'} style={width: '100%'} onClick={@handleSaveStart2} style={width: '100%'}>
                  保存为本地文件
                </Button>
              </Col>
            </Row>
            <Row>
              <Col lg={6} md={12} style={marginTop: 10}>
                <Input type="password" ref="uploadAuthPassword" id="devHelperSetPassword"
                  value={@state.uploadAuthPassword}
                  onChange={@handleSetPassword}
                  onClick={@selectInput.bind @, 'devHelperSetPassword'}
                  placeholder='请输入api.kcwki.moe服务器上传密码'
                  style={borderRadius: '5px', width: '90%', margin: '0 auto'} />
              </Col>
              <Col lg={6} md={12} style={marginTop: 10}>
                <Button ref="start2Path" bsStyle={if @state?.uploading then 'warning' else 'success'} style={width: '100%'} onClick={@handleUploadStart2}>
                  {if @state?.uploading then '上传中...' else '上传到服务器'}
                </Button>
              </Col>
            </Row>
          </Grid>
        </div>
        <div className="form-group">
          <Divider text={"地图点标记"} />
          <Grid>
            <Col sm={12} style={textAlign: 'center'} className={if @state?.isSortie then 'hidden-lg' else 'dummy'}>
              尚未出击
            </Col>
            <Row style={textAlign: 'center'} className={if not @state?.isSortie then 'hidden-lg' else 'dummy'}>
              <Col sm={12}>
                当前所在海域： {@state.mapArea} - {@state.mapInfo}
              </Col>
              <Col sm={6} style={marginTop: 10, lineHeight: '40px'}>
                地图点编号： {@state.cellId}
              </Col>
              <Col sm={6} style={marginTop: 10}>
                <Input type="text" ref="nextCell" id="devHelperSetNextCell"
                  value={@state.nextCell}
                  onChange={@handleSetNextCell}
                  onClick={@selectInput.bind @, 'devHelperSetNextCell'}
                  placeholder='请输入地图下一个进入点ABC序号'
                  style={borderRadius: '5px', width: '90%', margin: '0 auto'} />
              </Col>
              <Col sm={12} style={marginTop: 10}>
                <Button ref="start2Path" bsStyle={if @state?.uploading then 'warning' else 'success'} style={width: '50%', margin: '0 auto'} onClick={@handleUploadMapCell}>
                  {if @state?.cellUploading then '上传中...' else '上传到服务器'}
                </Button>
              </Col>
            </Row>
          </Grid>
        </div>
      </form>