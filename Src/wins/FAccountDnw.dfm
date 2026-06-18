object FrmAccountDnw: TFrmAccountDnw
  Left = 0
  Top = 0
  Caption = #44397#45236' '#44228#51340' '#51077#52636#44552
  ClientHeight = 294
  ClientWidth = 764
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
    Top = 45
    Width = 764
    Height = 249
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    Align = alClient
    BevelOuter = bvNone
    Caption = #44397#45236' '#44228#51340' '#51077#52636#44552
    TabOrder = 0
    object sg: TStringGrid
      Left = 0
      Top = 0
      Width = 774
      Height = 251
      Margins.Left = 5
      Margins.Top = 5
      Margins.Right = 5
      Margins.Bottom = 5
      Align = alClient
      DefaultColWidth = 150
      DefaultRowHeight = 29
      DefaultDrawing = False
      RowCount = 4
      FixedRows = 3
      TabOrder = 0
      OnDrawCell = sgDrawCell
      OnMouseDown = sgMouseDown
      ExplicitWidth = 764
      ExplicitHeight = 249
    end
  end
  object Panel2: TPanel
    Left = 0
    Top = 0
    Width = 764
    Height = 45
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 1
    DesignSize = (
      764
      45)
    object Button1: TButton
      Left = 602
      Top = 11
      Width = 132
      Height = 24
      Margins.Left = 5
      Margins.Top = 5
      Margins.Right = 5
      Margins.Bottom = 5
      Anchors = [akRight, akBottom]
      Caption = #51077#44552#54620#46020' '#49444#51221
      TabOrder = 0
      OnClick = Button1Click
      ExplicitLeft = 612
    end
    object Button2: TButton
      Left = 0
      Top = 11
      Width = 158
      Height = 24
      Margins.Left = 5
      Margins.Top = 5
      Margins.Right = 5
      Margins.Bottom = 5
      Caption = #50896#54868#51077#52636#44552#47532#49828#53944
      TabOrder = 1
      OnClick = Button2Click
    end
    object Button3: TButton
      Left = 168
      Top = 11
      Width = 161
      Height = 24
      Margins.Left = 5
      Margins.Top = 5
      Margins.Right = 5
      Margins.Bottom = 5
      Caption = #53076#51064#51204#49569#47532#49828#53944
      TabOrder = 2
      OnClick = Button3Click
    end
  end
  object Timer1: TTimer
    Enabled = False
    OnTimer = Timer1Timer
    Left = 56
    Top = 134
  end
  object Timer2: TTimer
    Tag = 1
    Enabled = False
    OnTimer = Timer2Timer
    Left = 112
    Top = 142
  end
end
