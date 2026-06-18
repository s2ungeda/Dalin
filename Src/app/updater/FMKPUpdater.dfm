object FrmMKPUpdater: TFrmMKPUpdater
  Left = 0
  Top = 0
  BorderStyle = bsNone
  Caption = 'FrmMKPUpdater'
  ClientHeight = 183
  ClientWidth = 473
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -18
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnClose = FormClose
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 144
  TextHeight = 25
  object Label1: TLabel
    Left = 10
    Top = 111
    Width = 51
    Height = 25
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    Caption = 'Label1'
  end
  object pb: TProgressBar
    Left = 10
    Top = 142
    Width = 363
    Height = 27
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    TabOrder = 0
  end
  object Button1: TButton
    Left = 388
    Top = 142
    Width = 72
    Height = 27
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    Caption = #51333#47308
    TabOrder = 1
    OnClick = Button1Click
  end
  object log: TMemo
    Left = 10
    Top = 10
    Width = 363
    Height = 96
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    ScrollBars = ssVertical
    TabOrder = 2
  end
  object http: TNetHTTPClient
    ConnectionTimeout = 10000
    SendTimeout = 10000
    ResponseTimeout = 10000
    UserAgent = 'Embarcadero URI Client/1.0'
    OnRequestCompleted = httpRequestCompleted
    OnReceiveData = httpReceiveData
    Left = 252
    Top = 124
  end
  object upTimer: TTimer
    Enabled = False
    Interval = 500
    OnTimer = upTimerTimer
    Left = 116
    Top = 108
  end
  object selfTimer: TTimer
    Enabled = False
    Interval = 500
    OnTimer = selfTimerTimer
    Left = 188
    Top = 96
  end
end
