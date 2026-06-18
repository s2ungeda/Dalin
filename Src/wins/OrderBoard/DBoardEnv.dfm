object BoardConfig: TBoardConfig
  Left = 0
  Top = 0
  Caption = 'Board Config'
  ClientHeight = 298
  ClientWidth = 428
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -17
  Font.Name = 'Tahoma'
  Font.Style = []
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 144
  TextHeight = 21
  object StringGridVolumes: TStringGrid
    Left = 12
    Top = 56
    Width = 263
    Height = 133
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    BorderStyle = bsNone
    ColCount = 3
    DefaultColWidth = 83
    FixedCols = 0
    FixedRows = 0
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goEditing]
    ScrollBars = ssNone
    TabOrder = 0
    OnKeyPress = StringGridVolumesKeyPress
    OnMouseWheelDown = StringGridVolumesMouseWheelDown
    OnMouseWheelUp = StringGridVolumesMouseWheelUp
  end
  object ComboBoxItem: TComboBox
    Left = 12
    Top = 12
    Width = 194
    Height = 21
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    ImeName = 'Microsoft IME 2003'
    TabOrder = 1
    OnChange = ComboBoxItemChange
  end
  object cbDefault: TCheckBox
    Left = 15
    Top = 204
    Width = 146
    Height = 26
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    Caption = 'Default Set'
    TabOrder = 2
    OnClick = cbDefaultClick
  end
  object ButtonOK: TButton
    Left = 12
    Top = 245
    Width = 113
    Height = 37
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    Caption = #54869#51064
    TabOrder = 3
    OnClick = ButtonOKClick
  end
  object edtAdd: TButton
    Left = 348
    Top = 56
    Width = 63
    Height = 37
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    Caption = 'Add'
    TabOrder = 4
    OnClick = edtAddClick
  end
  object edtDel: TButton
    Left = 348
    Top = 173
    Width = 63
    Height = 37
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    Caption = 'Delete'
    TabOrder = 5
    OnClick = edtDelClick
  end
  object edtName: TEdit
    Left = 296
    Top = 15
    Width = 112
    Height = 29
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    ImeName = 'Microsoft IME 2003'
    TabOrder = 6
  end
  object Button3: TButton
    Left = 296
    Top = 245
    Width = 112
    Height = 37
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    Caption = #52712#49548
    TabOrder = 7
    OnClick = Button3Click
  end
  object Button2: TButton
    Left = 348
    Top = 117
    Width = 63
    Height = 38
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    Caption = 'Clear'
    TabOrder = 8
    OnClick = Button2Click
  end
  object Button1: TButton
    Left = 162
    Top = 245
    Width = 113
    Height = 37
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    Caption = #51201#50857
    TabOrder = 9
    OnClick = Button1Click
  end
end
