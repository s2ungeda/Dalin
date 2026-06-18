object FrmServerMessage: TFrmServerMessage
  Left = 0
  Top = 0
  Caption = #49436#48260#47700#49464#51648
  ClientHeight = 269
  ClientWidth = 1101
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -17
  Font.Name = 'Tahoma'
  Font.Style = []
  OnClose = FormClose
  OnCreate = FormCreate
  PixelsPerInch = 144
  TextHeight = 21
  object lvLog: TListView
    Left = 0
    Top = 41
    Width = 1101
    Height = 228
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    Align = alClient
    Columns = <
      item
        Caption = #49884#44033
        Width = 150
      end
      item
        Caption = #47700#49464#51648#53076#46300
        Width = 45
      end
      item
        AutoSize = True
        Caption = #45236#50857
      end>
    TabOrder = 0
    ViewStyle = vsReport
    OnDrawItem = lvLogDrawItem
    ExplicitWidth = 1111
    ExplicitHeight = 230
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 1101
    Height = 41
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 1
    ExplicitWidth = 1111
    DesignSize = (
      1101
      41)
    object Button1: TButton
      Left = 953
      Top = 3
      Width = 113
      Height = 38
      Margins.Left = 5
      Margins.Top = 5
      Margins.Right = 5
      Margins.Bottom = 5
      Anchors = [akRight, akBottom]
      Caption = #49325#51228
      TabOrder = 0
      OnClick = Button1Click
      ExplicitLeft = 983
    end
    object cbAddLog: TCheckBox
      Left = 859
      Top = 6
      Width = 70
      Height = 32
      Margins.Left = 5
      Margins.Top = 5
      Margins.Right = 5
      Margins.Bottom = 5
      Anchors = [akRight, akBottom]
      Caption = #47196#44536
      Checked = True
      State = cbChecked
      TabOrder = 1
      ExplicitLeft = 889
    end
  end
end
