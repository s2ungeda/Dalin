object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Form1'
  ClientHeight = 766
  ClientWidth = 896
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -18
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 144
  TextHeight = 25
  object lv: TListView
    Left = 10
    Top = 60
    Width = 879
    Height = 517
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    Columns = <
      item
        Caption = #54028#51068#51060#47492
        Width = 200
      end
      item
        Caption = #48260#51204
        Width = 150
      end
      item
        Caption = #44221#47196
        Width = 150
      end
      item
        Caption = #54028#51068#53356#44592
        Width = 150
      end>
    TabOrder = 0
    ViewStyle = vsReport
  end
  object Edit1: TEdit
    Left = 10
    Top = 17
    Width = 263
    Height = 33
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    TabOrder = 1
  end
  object Button1: TButton
    Left = 345
    Top = 17
    Width = 75
    Height = 33
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    Caption = 'Display'
    TabOrder = 2
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 671
    Top = 17
    Width = 75
    Height = 33
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    Caption = 'MakeFile'
    TabOrder = 3
    OnClick = Button2Click
  end
  object Edit2: TEdit
    Left = 432
    Top = 17
    Width = 229
    Height = 33
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    TabOrder = 4
  end
  object ReLoad: TButton
    Left = 812
    Top = 17
    Width = 75
    Height = 33
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    Caption = 'ReLoad'
    TabOrder = 5
    OnClick = ReLoadClick
  end
  object Edit3: TEdit
    Left = 276
    Top = 17
    Width = 61
    Height = 33
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    TabOrder = 6
  end
  object lvig: TListView
    Left = 10
    Top = 587
    Width = 879
    Height = 169
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    Columns = <
      item
      end
      item
        Caption = #47924#49884#54028#51068
        Width = 500
      end
      item
        Width = 200
      end>
    TabOrder = 7
    ViewStyle = vsReport
  end
end
