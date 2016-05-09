{remote} = require 'electron'
{dialog} = remote.require 'electron'
fs = require 'fs-extra'
path = require 'path-extra'
{Grid, Col} = ReactBootstrap
{config, React, ROOT} = window
# Parameters:
#   label       String         The title to display
#   configName  String         Where you store in config
#   defaultVal  Bool           The default value for config
#   onNewVal    Function(val)  Called when a new value is set.
module.exports = React.createClass
  getInitialState: ->
    myval: config.get @props.configName, @props.defaultVal
  onDrag: (e) ->
    e.preventDefault()
  synchronize: (callback) ->
    return if @lock
    @lock = true
    callback()
    @lock = false
  setPath: (val) ->
    @props.onNewVal(val) if @props.onNewVal
    config.set @props.configName, val
    @setState
      myval: val
  folderPickerOnDrop: (e) ->
    e.preventDefault()
    droppedFiles = e.dataTransfer.files
    isDirectory = fs.statSync(droppedFiles[0].path).isDirectory()
    @setPath droppedFiles[0].path if isDirectory
  folderPickerOnClick: ->
    @synchronize =>
      fs.ensureDirSync @state.myval
      filenames = dialog.showOpenDialog
        title: @props.label
        defaultPath: @state.myval
        properties: ['openDirectory', 'createDirectory']
      @setPath filenames[0] if filenames isnt undefined
  folderPickerStyle:
    width: '100%'
    height: '100%'
    borderWidth: '2px'
    borderColor: '#666'
    borderStyle: 'dashed'
    borderRadius: '0'
    textAlign: 'center'
    padding: '5px'
    cursor: 'pointer'
  render: ->
    <Grid>
      <Col xs={12}>
        <div className="folder-picker"
             style={@folderPickerStyle}
             onClick={@folderPickerOnClick}
             onDrop={@folderPickerOnDrop}
             onDragEnter={@onDrag}
             onDragOver={@onDrag}
             onDragLeave={@onDrag}>
          {@state.myval}
        </div>
      </Col>    
    </Grid>
