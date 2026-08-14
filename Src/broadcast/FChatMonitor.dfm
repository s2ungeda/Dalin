object FrmChatComm: TFrmChatComm
  Left = 0
  Top = 0
  Caption = 'UDP Chat'
  ClientHeight = 780
  ClientWidth = 1350
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -18
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnClose = FormClose
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 144
  TextHeight = 25
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 1350
    Height = 98
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    ExplicitWidth = 1340
    object lblName: TLabel
      Left = 24
      Top = 15
      Width = 51
      Height = 25
      Margins.Left = 5
      Margins.Top = 5
      Margins.Right = 5
      Margins.Bottom = 5
      Caption = 'Name:'
    end
    object lblUDPPort: TLabel
      Left = 279
      Top = 15
      Width = 76
      Height = 25
      Margins.Left = 5
      Margins.Top = 5
      Margins.Right = 5
      Margins.Bottom = 5
      Caption = 'UDP Port:'
    end
    object lblTCPPort: TLabel
      Left = 399
      Top = 15
      Width = 70
      Height = 25
      Margins.Left = 5
      Margins.Top = 5
      Margins.Right = 5
      Margins.Bottom = 5
      Caption = 'TCP Port:'
    end
    object lblBroadcast: TLabel
      Left = 519
      Top = 15
      Width = 82
      Height = 25
      Margins.Left = 5
      Margins.Top = 5
      Margins.Right = 5
      Margins.Bottom = 5
      Caption = 'Broadcast:'
    end
    object lblInterval: TLabel
      Left = 908
      Top = 15
      Width = 98
      Height = 25
      Margins.Left = 5
      Margins.Top = 5
      Margins.Right = 5
      Margins.Bottom = 5
      Caption = 'Interval (sec)'
    end
    object edtName: TEdit
      Left = 24
      Top = 45
      Width = 240
      Height = 33
      Margins.Left = 5
      Margins.Top = 5
      Margins.Right = 5
      Margins.Bottom = 5
      TabOrder = 0
    end
    object edtUDPPort: TEdit
      Left = 279
      Top = 45
      Width = 105
      Height = 33
      Margins.Left = 5
      Margins.Top = 5
      Margins.Right = 5
      Margins.Bottom = 5
      TabOrder = 1
    end
    object edtTCPPort: TEdit
      Left = 399
      Top = 45
      Width = 105
      Height = 33
      Margins.Left = 5
      Margins.Top = 5
      Margins.Right = 5
      Margins.Bottom = 5
      TabOrder = 2
    end
    object edtBroadcast: TEdit
      Left = 519
      Top = 45
      Width = 360
      Height = 33
      Margins.Left = 5
      Margins.Top = 5
      Margins.Right = 5
      Margins.Bottom = 5
      TabOrder = 3
    end
    object edtInterval: TEdit
      Left = 908
      Top = 45
      Width = 105
      Height = 33
      Margins.Left = 5
      Margins.Top = 5
      Margins.Right = 5
      Margins.Bottom = 5
      TabOrder = 4
    end
    object btnUpdateInterval: TButton
      Left = 1020
      Top = 42
      Width = 98
      Height = 41
      Margins.Left = 5
      Margins.Top = 5
      Margins.Right = 5
      Margins.Bottom = 5
      Caption = 'Update'
      TabOrder = 5
      OnClick = btnUpdateIntervalClick
    end
    object btnStart: TButton
      Left = 1200
      Top = 42
      Width = 128
      Height = 41
      Margins.Left = 5
      Margins.Top = 5
      Margins.Right = 5
      Margins.Bottom = 5
      Caption = 'Start'
      TabOrder = 6
      OnClick = btnStartClick
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 683
    Width = 1350
    Height = 97
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    ExplicitTop = 681
    ExplicitWidth = 1340
    object lblFX: TLabel
      Left = 24
      Top = 15
      Width = 20
      Height = 25
      Margins.Left = 5
      Margins.Top = 5
      Margins.Right = 5
      Margins.Bottom = 5
      Caption = 'FX'
    end
    object lblDomestic: TLabel
      Left = 234
      Top = 15
      Width = 117
      Height = 25
      Margins.Left = 5
      Margins.Top = 5
      Margins.Right = 5
      Margins.Bottom = 5
      Caption = 'Total Domestic'
    end
    object lblCoin: TLabel
      Left = 564
      Top = 15
      Width = 78
      Height = 25
      Margins.Left = 5
      Margins.Top = 5
      Margins.Right = 5
      Margins.Bottom = 5
      Caption = 'Total Coin'
    end
    object edtFX: TEdit
      Left = 24
      Top = 45
      Width = 195
      Height = 33
      Margins.Left = 5
      Margins.Top = 5
      Margins.Right = 5
      Margins.Bottom = 5
      ReadOnly = True
      TabOrder = 0
    end
    object edtDomestic: TEdit
      Left = 234
      Top = 45
      Width = 315
      Height = 33
      Margins.Left = 5
      Margins.Top = 5
      Margins.Right = 5
      Margins.Bottom = 5
      ReadOnly = True
      TabOrder = 1
    end
    object edtCoin: TEdit
      Left = 564
      Top = 45
      Width = 315
      Height = 33
      Margins.Left = 5
      Margins.Top = 5
      Margins.Right = 5
      Margins.Bottom = 5
      ReadOnly = True
      TabOrder = 2
    end
    object btnPauseResume: TButton
      Left = 908
      Top = 44
      Width = 185
      Height = 40
      Margins.Left = 5
      Margins.Top = 5
      Margins.Right = 5
      Margins.Bottom = 5
      Caption = 'Pause Auto'
      TabOrder = 3
      OnClick = btnPauseResumeClick
    end
    object btnSend: TButton
      Left = 1103
      Top = 44
      Width = 128
      Height = 40
      Margins.Left = 5
      Margins.Top = 5
      Margins.Right = 5
      Margins.Bottom = 5
      Caption = 'Send'
      Default = True
      TabOrder = 4
      OnClick = btnSendClick
    end
    object Button1: TButton
      Left = 1253
      Top = 58
      Width = 75
      Height = 26
      Margins.Left = 5
      Margins.Top = 5
      Margins.Right = 5
      Margins.Bottom = 5
      Caption = #47196#44536#49325#51228
      TabOrder = 5
      OnClick = Button1Click
    end
  end
  object pnlRight: TPanel
    Left = 998
    Top = 98
    Width = 352
    Height = 585
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    Align = alRight
    BevelOuter = bvNone
    TabOrder = 2
    ExplicitLeft = 988
    ExplicitHeight = 583
    object lblPeers: TLabel
      Left = 0
      Top = 0
      Width = 352
      Height = 25
      Margins.Left = 5
      Margins.Top = 5
      Margins.Right = 5
      Margins.Bottom = 5
      Align = alTop
      Alignment = taCenter
      Caption = 'Peers'
      Layout = tlCenter
      ExplicitWidth = 41
    end
    object lstPeers: TListBox
      Left = 0
      Top = 25
      Width = 352
      Height = 560
      Margins.Left = 5
      Margins.Top = 5
      Margins.Right = 5
      Margins.Bottom = 5
      Align = alClient
      ItemHeight = 25
      TabOrder = 0
      ExplicitTop = 120
      ExplicitHeight = 465
    end
  end
  object memLog: TMemo
    Left = 0
    Top = 98
    Width = 998
    Height = 585
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    Align = alClient
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 3
    ExplicitWidth = 988
    ExplicitHeight = 583
  end
end
