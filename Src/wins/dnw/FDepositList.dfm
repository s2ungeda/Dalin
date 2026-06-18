object FrmDepositList: TFrmDepositList
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = #51077#44552#51452#49548' '#52628#44032
  ClientHeight = 160
  ClientWidth = 678
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -18
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poOwnerFormCenter
  OnClose = FormClose
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 144
  TextHeight = 25
  object lbResult: TLabel
    Left = 9
    Top = 120
    Width = 5
    Height = 25
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 678
    Height = 42
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    Align = alTop
    TabOrder = 0
    ExplicitWidth = 644
    object lbDesc: TLabel
      Left = 492
      Top = 8
      Width = 5
      Height = 25
      Margins.Left = 5
      Margins.Top = 5
      Margins.Right = 5
      Margins.Bottom = 5
    end
    object edtCode: TEdit
      Left = 105
      Top = 4
      Width = 122
      Height = 33
      Margins.Left = 5
      Margins.Top = 5
      Margins.Right = 5
      Margins.Bottom = 5
      TabOrder = 0
      OnKeyDown = edtCodeKeyDown
    end
    object cbNetType: TComboBox
      Left = 230
      Top = 4
      Width = 149
      Height = 33
      Margins.Left = 5
      Margins.Top = 5
      Margins.Right = 5
      Margins.Bottom = 5
      Style = csDropDownList
      TabOrder = 1
      OnChange = cbNetTypeChange
    end
    object Button1: TButton
      Left = 383
      Top = 4
      Width = 98
      Height = 33
      Margins.Left = 5
      Margins.Top = 5
      Margins.Right = 5
      Margins.Bottom = 5
      Caption = #51312#54924
      TabOrder = 2
      OnClick = Button1Click
    end
    object cbExKind: TComboBox
      Left = 0
      Top = 4
      Width = 103
      Height = 33
      Margins.Left = 5
      Margins.Top = 5
      Margins.Right = 5
      Margins.Bottom = 5
      Style = csDropDownList
      TabOrder = 3
      OnChange = cbExKindChange
    end
    object btnCreate: TButton
      Left = 594
      Top = 4
      Width = 78
      Height = 33
      Margins.Left = 5
      Margins.Top = 5
      Margins.Right = 5
      Margins.Bottom = 5
      Caption = #49373#49457
      TabOrder = 4
      OnClick = btnCreateClick
    end
  end
  object sgAddr: TStringGrid
    Left = 0
    Top = 42
    Width = 678
    Height = 67
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    Align = alTop
    ColCount = 3
    DefaultColWidth = 96
    DefaultRowHeight = 29
    DefaultDrawing = False
    RowCount = 2
    FixedRows = 0
    ScrollBars = ssVertical
    TabOrder = 1
    OnDrawCell = sgAddrDrawCell
    ExplicitWidth = 644
    ColWidths = (
      147
      485
      30)
  end
  object btnAddr1: TButton
    Left = 640
    Top = 45
    Width = 27
    Height = 26
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    Caption = '#$2398'
    TabOrder = 2
    OnClick = btnAddr1Click
  end
  object btnAddr2: TButton
    Left = 640
    Top = 75
    Width = 27
    Height = 26
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    TabOrder = 3
    OnClick = btnAddr2Click
  end
  object Button2: TButton
    Left = 506
    Top = 118
    Width = 78
    Height = 38
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    Caption = #52712#49548
    TabOrder = 4
    OnClick = Button2Click
  end
  object Button3: TButton
    Left = 594
    Top = 118
    Width = 78
    Height = 38
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    Caption = #51200#51109
    TabOrder = 5
    OnClick = Button3Click
  end
end
