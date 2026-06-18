object FrmPriceTable: TFrmPriceTable
  Left = 549
  Top = 75
  Caption = #44608#54532#54788#54889#54364
  ClientHeight = 788
  ClientWidth = 1545
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -17
  Font.Name = 'Tahoma'
  Font.Style = []
  Position = poDesigned
  OnActivate = FormActivate
  OnClose = FormClose
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 144
  TextHeight = 21
  object StatusBar1: TStatusBar
    Left = 0
    Top = 758
    Width = 1545
    Height = 30
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    Panels = <>
    ExplicitTop = 756
    ExplicitWidth = 1535
  end
  object plLeft: TPanel
    Left = 0
    Top = 0
    Width = 1545
    Height = 758
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    Align = alClient
    BevelOuter = bvNone
    Caption = 'plLeft'
    TabOrder = 1
    ExplicitWidth = 1535
    ExplicitHeight = 756
    object plLeftClient: TPanel
      Left = 0
      Top = 0
      Width = 1545
      Height = 758
      Margins.Left = 5
      Margins.Top = 5
      Margins.Right = 5
      Margins.Bottom = 5
      Align = alClient
      AutoSize = True
      BevelOuter = bvNone
      TabOrder = 0
      ExplicitWidth = 1535
      ExplicitHeight = 756
      object sgKimp: TStringGrid
        Left = 0
        Top = 48
        Width = 1545
        Height = 710
        Margins.Left = 5
        Margins.Top = 5
        Margins.Right = 5
        Margins.Bottom = 5
        Align = alClient
        ColCount = 13
        DefaultColWidth = 96
        DefaultRowHeight = 29
        DefaultDrawing = False
        FixedCols = 0
        RowCount = 34
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -17
        Font.Name = 'Tahoma'
        Font.Style = []
        Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goColSizing, goFixedRowDefAlign]
        ParentFont = False
        PopupMenu = PopupMenu1
        TabOrder = 0
        OnDrawCell = sgKimpDrawCell
        OnKeyDown = sgKimpKeyDown
        OnMouseDown = sgKimpMouseDown
        ExplicitWidth = 1535
        ExplicitHeight = 708
      end
      object plLeftTop: TPanel
        Left = 0
        Top = 0
        Width = 1545
        Height = 48
        Margins.Left = 5
        Margins.Top = 5
        Margins.Right = 5
        Margins.Bottom = 5
        Align = alTop
        BevelOuter = bvLowered
        ParentBackground = False
        TabOrder = 1
        ExplicitWidth = 1535
        DesignSize = (
          1545
          48)
        object Refresh: TButton
          Left = 1442
          Top = 6
          Width = 72
          Height = 38
          Margins.Left = 5
          Margins.Top = 5
          Margins.Right = 5
          Margins.Bottom = 5
          Anchors = [akRight, akBottom]
          Caption = #51201#50857
          TabOrder = 0
          OnClick = RefreshClick
          ExplicitLeft = 1432
        end
        object cbAuto: TCheckBox
          Left = 1206
          Top = 11
          Width = 60
          Height = 25
          Margins.Left = 5
          Margins.Top = 5
          Margins.Right = 5
          Margins.Bottom = 5
          Anchors = [akRight, akBottom]
          Caption = 'Auto'
          Checked = True
          State = cbChecked
          TabOrder = 1
          OnClick = cbAutoClick
          ExplicitLeft = 1196
        end
        object edtSec: TLabeledEdit
          Left = 1277
          Top = 8
          Width = 57
          Height = 29
          Margins.Left = 5
          Margins.Top = 5
          Margins.Right = 5
          Margins.Bottom = 5
          Alignment = taRightJustify
          Anchors = [akRight, akBottom]
          EditLabel.Width = 83
          EditLabel.Height = 29
          EditLabel.Margins.Left = 17
          EditLabel.Margins.Top = 17
          EditLabel.Margins.Right = 17
          EditLabel.Margins.Bottom = 17
          EditLabel.Caption = '('#45800#50948' : '#48128#47532' )'
          LabelPosition = lpRight
          NumbersOnly = True
          TabOrder = 2
          Text = '200'
          ExplicitLeft = 1267
        end
      end
    end
  end
  object PopupMenu1: TPopupMenu
    Left = 368
    Top = 216
  end
  object refreshTimer: TTimer
    Enabled = False
    OnTimer = refreshTimerTimer
    Left = 208
    Top = 144
  end
end
