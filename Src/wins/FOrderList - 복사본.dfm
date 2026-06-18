object FrmOrderList: TFrmOrderList
  Left = 0
  Top = 0
  Caption = #51452#47928#47532#49828#53944
  ClientHeight = 438
  ClientWidth = 1342
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -17
  Font.Name = 'Tahoma'
  Font.Style = []
  OnClose = FormClose
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 144
  TextHeight = 21
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 1342
    Height = 38
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    Align = alTop
    TabOrder = 0
    ExplicitWidth = 1332
    object ComboBox1: TComboBox
      Left = 8
      Top = 3
      Width = 102
      Height = 29
      Margins.Left = 5
      Margins.Top = 5
      Margins.Right = 5
      Margins.Bottom = 5
      Style = csDropDownList
      ItemIndex = 0
      TabOrder = 0
      Text = #51204#52404
      OnChange = ComboBox1Change
      Items.Strings = (
        #51204#52404
        #48148#51060#45240#49828
        #50629#48708#53944
        #48727#50040)
    end
    object CheckBox1: TCheckBox
      Left = 122
      Top = 8
      Width = 64
      Height = 24
      Margins.Left = 5
      Margins.Top = 5
      Margins.Right = 5
      Margins.Bottom = 5
      Caption = #51217#49688
      Checked = True
      State = cbChecked
      TabOrder = 1
      OnClick = CheckBox1Click
    end
    object CheckBox2: TCheckBox
      Tag = 1
      Left = 207
      Top = 8
      Width = 60
      Height = 24
      Margins.Left = 5
      Margins.Top = 5
      Margins.Right = 5
      Margins.Bottom = 5
      Caption = #52404#44208
      Checked = True
      State = cbChecked
      TabOrder = 2
      OnClick = CheckBox1Click
    end
    object CheckBox3: TCheckBox
      Tag = 2
      Left = 290
      Top = 8
      Width = 61
      Height = 24
      Margins.Left = 5
      Margins.Top = 5
      Margins.Right = 5
      Margins.Bottom = 5
      Caption = #52712#49548
      TabOrder = 3
      OnClick = CheckBox1Click
    end
    object CheckBox4: TCheckBox
      Tag = 3
      Left = 365
      Top = 8
      Width = 61
      Height = 24
      Margins.Left = 5
      Margins.Top = 5
      Margins.Right = 5
      Margins.Bottom = 5
      Caption = #44144#48512
      TabOrder = 4
      OnClick = CheckBox1Click
    end
    object edtCode: TEdit
      Left = 452
      Top = 3
      Width = 87
      Height = 29
      Margins.Left = 5
      Margins.Top = 5
      Margins.Right = 5
      Margins.Bottom = 5
      TabOrder = 5
      OnKeyDown = edtCodeKeyDown
    end
    object cbCode: TCheckBox
      Left = 548
      Top = 8
      Width = 88
      Height = 25
      Margins.Left = 5
      Margins.Top = 5
      Margins.Right = 5
      Margins.Bottom = 5
      Caption = #51333#47785#54596#53552
      TabOrder = 6
      OnClick = cbCodeClick
    end
    object btnNext: TButton
      Left = 663
      Top = 3
      Width = 55
      Height = 29
      Margins.Left = 5
      Margins.Top = 5
      Margins.Right = 5
      Margins.Bottom = 5
      Caption = #45796#51020
      Enabled = False
      TabOrder = 7
      OnClick = btnNextClick
    end
  end
  object sgOrder: TStringGrid
    Left = 0
    Top = 38
    Width = 1342
    Height = 400
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    Align = alClient
    DefaultColWidth = 96
    DefaultColAlignment = taCenter
    DefaultRowHeight = 29
    DefaultDrawing = False
    FixedCols = 0
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goColSizing, goFixedRowDefAlign]
    ScrollBars = ssVertical
    TabOrder = 1
    OnDrawCell = sgOrderDrawCell
    OnMouseDown = sgOrderMouseDown
    ExplicitWidth = 1332
    ExplicitHeight = 398
  end
  object PopupMenu1: TPopupMenu
    Left = 512
    Top = 208
    object N1: TMenuItem
      Caption = #52712#49548#51452#47928
      OnClick = N1Click
    end
    object N2: TMenuItem
      Caption = #49345#49464#51221#48372
      OnClick = N2Click
    end
  end
end
