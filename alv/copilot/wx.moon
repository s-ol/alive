----
-- wxLua Copilot GUI.
--
-- @classmod WXCopilot
import Logger, version from require 'alv'
import parse_args, Copilot from require 'alv.copilot.base'

require 'wx'
import
  wxID_ABOUT, wxID_OPEN, wxID_EXIT, wxID_ANY, wxVERTICAL,
  wxFrame, wxMenuBar, wxMenu, wxPanel, wxBoxSizer, wxTextCtrl, wxSplitterWindow
from wx

STARTSTOP = 100

class WXLogger extends Logger
  new: (level, @eval_ctrl, @run_ctrl) =>
    super level

  set_time: (time) =>
    @ctrl = switch time
      when 'eval' then @eval_ctrl
      when 'run' then @run_ctrl
      else error "invalid time '#{time}'"
 
  put: (message) =>
    @ctrl\AppendText message .. '\n'

class WXCopilot extends Copilot
  new: (arg) =>
    super parse_args arg

    @app = wx.wxGetApp!
    @app.VendorName = 'alive'
    @app.AppName = 'alive wxCopilot'

    fileMenu = wxMenu {
      { wxID_ABOUT, '&About',        'About alive wxCopilot' }
      { wxID_OPEN,  '&Open\tCtrl-O', 'Open Script'           }
      {                                                      }
      { wxID_EXIT,  'E&xit\tCtrl-Q', 'Exit Program'          }
    }
    runMenu = wxMenu {
      { STARTSTOP, '&Start/Stop\tCtrl-P', 'Start/Stop Script Execution' }
    }
    @menuBar = with wxMenuBar!
      \Append fileMenu, '&File'
      \Append runMenu, '&Run'

    @frame = wxFrame wx.NULL, wxID_ANY, @app\GetAppName!
    @frame\SetMenuBar @menuBar
    @status = @frame\CreateStatusBar 1

    @update_status!

    splitter = wxSplitterWindow @frame, wx.wxID_ANY

    eval, @eval_ctrl = @mkPanel splitter, 'eval-time messages'

    run, @run_ctrl = @mkPanel splitter, 'run-time messages'

    splitter\SetMinimumPaneSize 60
    splitter\SplitHorizontally eval, run, 0

    sizer = with wxBoxSizer wx.wxVERTICAL
      \Add splitter, 1, wx.wxEXPAND + wx.wxALL, 10

    @frame\SetAutoLayout true
    @frame\SetSizer sizer
    @frame\Show true

    @frame\Connect wxID_ABOUT, wx.wxEVT_COMMAND_MENU_SELECTED, @\do_about
    @frame\Connect wxID_OPEN, wx.wxEVT_COMMAND_MENU_SELECTED, @\do_open
    @frame\Connect wxID_EXIT, wx.wxEVT_COMMAND_MENU_SELECTED, -> @frame\Close!
    @frame\Connect STARTSTOP, wx.wxEVT_COMMAND_MENU_SELECTED, @\do_startstop
    @frame\Connect wxID_ANY, wx.wxEVT_IDLE, @\do_idle

  do_about: =>
    wx.wxMessageBox "alive #{version.tag} wxCopilot.

built using #{wxlua.wxLUA_VERSION_STRING} on #{wx.wxVERSION_STRING}",
      "About wxCopilot",
      wx.wxOK + wx.wxICON_INFORMATION,
      @frame

  do_open: =>
    dialog = wx.wxFileDialog @frame, 'Change Script', '', '',
                             'Alive scripts (*.alv)|*.alv|All files (*)|*',
                             wx.wxFD_OPEN + wx.wxFD_FILE_MUST_EXIST

    if dialog\ShowModal! == wx.wxID_OK
      @paused = false
      @open dialog\GetPath!
      @update_status!

    dialog\Destroy!

  do_startstop: (event) =>
    if @file
      @paused = not @paused
      @update_status!

  do_idle: (event) =>
    if not @paused
      event\RequestMore true
      @tick!

  update_status: =>
    startstop = @menuBar\FindItem STARTSTOP
    if not @file
      @status\SetStatusText "No script loaded."
      startstop\Enable false
    else
      startstop\Enable true
      if @paused
        @status\SetStatusText "Paused."
      else
        @status\SetStatusText "Running."

  mkPanel: (parent, name) =>
    panel = wxPanel parent, wxID_ANY
    sizer = wxBoxSizer wxVERTICAL
    panel\SetSizer sizer

    sizer\Add wx.wxStaticText panel, wx.wxID_ANY, name
    log = wxTextCtrl panel, wxID_ANY, '', wx.wxDefaultPosition,
                     wx.wxDefaultSize, wx.wxTE_MULTILINE + wx.wxTE_READONLY
    sizer\Add log, 1, wx.wxEXPAND | wx.wxBOTTOM, 5

    panel, log

  run: =>
    WXLogger\init @args.log, copilot.eval_ctrl, copilot.run_ctrl
    @app\MainLoop!

{
  :WXCopilot
}
