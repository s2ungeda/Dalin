object FrmAccountDnwConfig: TFrmAccountDnwConfig
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = #44397#45236#44144#47000#49548' '#50896#54868' '#51077#52636#44552#54620#46020' ('#50613#50896')'
  ClientHeight = 151
  ClientWidth = 472
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -18
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnCreate = FormCreate
  PixelsPerInch = 144
  TextHeight = 25
  object sg: TStringGrid
    Left = 6
    Top = 10
    Width = 459
    Height = 99
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    ColCount = 3
    DefaultColWidth = 150
    DefaultRowHeight = 29
    RowCount = 3
    TabOrder = 0
    OnKeyPress = sgKeyPress
    OnMouseUp = sgMouseUp
  end
  object Button1: TButton
    Left = 288
    Top = 119
    Width = 75
    Height = 26
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    Caption = #54869#51064
    TabOrder = 1
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 390
    Top = 119
    Width = 75
    Height = 26
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    Caption = #52712#49548
    TabOrder = 2
    OnClick = Button2Click
  end
end
