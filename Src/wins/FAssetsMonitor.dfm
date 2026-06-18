object FrmAssetMonitor: TFrmAssetMonitor
  Left = 0
  Top = 0
  Caption = #51088#49328' '#53580#49828#53944'  '#47784#45768#53552
  ClientHeight = 673
  ClientWidth = 1119
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -18
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnClose = FormClose
  OnCreate = FormCreate
  PixelsPerInch = 144
  TextHeight = 25
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 1119
    Height = 49
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    Align = alTop
    TabOrder = 0
    object edtCode: TEdit
      Left = 94
      Top = 12
      Width = 109
      Height = 33
      Margins.Left = 5
      Margins.Top = 5
      Margins.Right = 5
      Margins.Bottom = 5
      TabOrder = 0
      Text = 'XRP'
    end
    object CheckBox1: TCheckBox
      Left = 505
      Top = 17
      Width = 86
      Height = 17
      Margins.Left = 5
      Margins.Top = 5
      Margins.Right = 5
      Margins.Bottom = 5
      Caption = #51312#54924
      TabOrder = 1
      OnClick = CheckBox1Click
    end
    object Button1: TButton
      Left = 601
      Top = 13
      Width = 108
      Height = 26
      Margins.Left = 5
      Margins.Top = 5
      Margins.Right = 5
      Margins.Bottom = 5
      Caption = #47196#44536' Clear'
      TabOrder = 2
      OnClick = Button1Click
    end
    object ComboBox1: TComboBox
      Left = 0
      Top = 12
      Width = 85
      Height = 30
      Margins.Left = 5
      Margins.Top = 5
      Margins.Right = 5
      Margins.Bottom = 5
      Style = csOwnerDrawFixed
      ItemHeight = 24
      ItemIndex = 0
      TabOrder = 3
      Text = 'Upbit'
      OnChange = ComboBox1Change
      Items.Strings = (
        'Upbit'
        'Bithumb')
    end
    object Button2: TButton
      Left = 213
      Top = 12
      Width = 75
      Height = 33
      Margins.Left = 5
      Margins.Top = 5
      Margins.Right = 5
      Margins.Bottom = 5
      Caption = #51201#50857
      TabOrder = 4
      OnClick = Button2Click
    end
  end
  object sgKRW: TStringGrid
    Left = 0
    Top = 55
    Width = 553
    Height = 98
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    ColCount = 4
    DefaultColWidth = 150
    DefaultRowHeight = 29
    RowCount = 3
    TabOrder = 1
    ColWidths = (
      90
      150
      150
      150)
  end
  object sgCoin: TStringGrid
    Left = 563
    Top = 55
    Width = 553
    Height = 98
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    ColCount = 4
    DefaultColWidth = 150
    DefaultRowHeight = 29
    RowCount = 3
    TabOrder = 2
    ColWidths = (
      90
      150
      150
      150)
  end
  object mKRW: TMemo
    Left = 0
    Top = 163
    Width = 553
    Height = 242
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 3
  end
  object mKRW2: TMemo
    Left = 0
    Top = 415
    Width = 553
    Height = 250
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 4
  end
  object mCoin: TMemo
    Left = 563
    Top = 163
    Width = 553
    Height = 242
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 5
  end
  object mCoin2: TMemo
    Left = 563
    Top = 415
    Width = 553
    Height = 250
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 6
  end
  object Timer1: TTimer
    Enabled = False
    OnTimer = Timer1Timer
    Left = 656
    Top = 36
  end
end
