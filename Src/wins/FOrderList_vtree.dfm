object FrmOrderList: TFrmOrderList
  Left = 0
  Top = 0
  Caption = #51452#47928#47532#49828#53944
  ClientHeight = 438
  ClientWidth = 1361
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
    Width = 1361
    Height = 38
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    Align = alTop
    TabOrder = 0
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
      Width = 56
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
  object vstOrder: TVirtualStringTree
    Left = 0
    Top = 38
    Width = 1361
    Height = 369
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    Align = alClient
    DefaultNodeHeight = 22
    Header.AutoSizeIndex = -1
    Header.Height = 24
    Header.MainColumn = -1
    Header.Options = [hoColumnResize, hoVisible]
    Header.Style = hsFlatButtons
    Indent = 0
    Margin = 4
    TabOrder = 1
    TextMargin = 4
    TreeOptions.MiscOptions = [toFullRepaintOnResize, toGridExtensions, toInitOnSave, toWheelPanning]
    TreeOptions.PaintOptions = [toHideFocusRect, toShowHorzGridLines, toShowVertGridLines, toThemeAware]
    TreeOptions.SelectionOptions = [toExtendedFocus, toFullRowSelect]
    OnBeforeCellPaint = vstOrderBeforeCellPaint
    OnFreeNode = vstOrderFreeNode
    OnGetText = vstOrderGetText
    OnPaintText = vstOrderPaintText
    OnGetNodeDataSize = vstOrderGetNodeDataSize
    OnNodeDblClick = vstOrderNodeDblClick
    OnMouseDown = vstOrderMouseDown
    Touch.InteractiveGestures = [igPan, igPressAndTap]
    Touch.InteractiveGestureOptions = [igoPanSingleFingerHorizontal, igoPanSingleFingerVertical, igoPanInertia, igoPanGutter, igoParentPassthrough]
    Columns = <>
  end
  object Panel2: TPanel
    Left = 0
    Top = 407
    Width = 1361
    Height = 31
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    Align = alBottom
    TabOrder = 2
    object Label1: TLabel
      Left = 11
      Top = 5
      Width = 407
      Height = 21
      Margins.Left = 5
      Margins.Top = 5
      Margins.Right = 5
      Margins.Bottom = 5
      Caption = '* Bithumb '#50808#48512'('#44144#47000#49548' '#54856#54168#51060#51648' '#46608#45716' '#50545') '#51452#47928#51008' Dalin '#50640' '#48152#50689#50504#46120
      Color = clBtnFace
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clPurple
      Font.Height = -17
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentColor = False
      ParentFont = False
    end
  end
  object PopupMenu1: TPopupMenu
    Left = 512
    Top = 208
    object N1: TMenuItem
      Caption = #52712#49548#51452#47928
      OnClick = N1Click
    end
    object N2: TMenuItem
      Caption = #51452#47928#48264#54840#48373#49324
      OnClick = N2Click
    end
    object N3: TMenuItem
      Caption = '-'
    end
    object N4: TMenuItem
      Caption = #49345#53468#51312#54924
      OnClick = N4Click
    end
  end
end
