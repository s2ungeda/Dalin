object FrmAccountDnwList: TFrmAccountDnwList
  Left = 0
  Top = 0
  Caption = 'FrmAccountDnwList'
  ClientHeight = 1142
  ClientWidth = 600
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
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 600
    Height = 41
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    Align = alTop
    Alignment = taLeftJustify
    TabOrder = 0
    ExplicitWidth = 590
    DesignSize = (
      600
      41)
    object Button1: TButton
      Left = 431
      Top = 8
      Width = 68
      Height = 27
      Margins.Left = 5
      Margins.Top = 5
      Margins.Right = 5
      Margins.Bottom = 5
      Anchors = [akRight, akBottom]
      Caption = #51312' '#54924
      TabOrder = 0
      OnClick = Button1Click
      ExplicitLeft = 421
    end
    object btnNext: TButton
      Left = 510
      Top = 8
      Width = 62
      Height = 26
      Margins.Left = 5
      Margins.Top = 5
      Margins.Right = 5
      Margins.Bottom = 5
      Anchors = [akRight, akBottom]
      Caption = 'Next'
      TabOrder = 1
      OnClick = btnNextClick
      ExplicitLeft = 500
    end
  end
  object stBar: TStatusBar
    Left = 0
    Top = 1112
    Width = 600
    Height = 30
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    Panels = <
      item
        Width = 100
      end
      item
        Width = 50
      end>
    ExplicitTop = 1110
    ExplicitWidth = 590
  end
  object sg: TStringGrid
    Left = 0
    Top = 41
    Width = 600
    Height = 1071
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    Align = alClient
    DefaultColWidth = 96
    DefaultRowHeight = 36
    DefaultDrawing = False
    FixedCols = 0
    TabOrder = 2
    OnDrawCell = sgDrawCell
    OnMouseDown = sgMouseDown
    ExplicitWidth = 590
    ExplicitHeight = 1069
  end
  object Timer1: TTimer
    Enabled = False
    OnTimer = Timer1Timer
    Left = 224
    Top = 200
  end
end
