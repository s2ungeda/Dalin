object FrmJungKopi: TFrmJungKopi
  Left = 0
  Top = 0
  Caption = 'INDEX KIP'
  ClientHeight = 141
  ClientWidth = 1227
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnClose = FormClose
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object sgVal: TStringGrid
    Left = 0
    Top = 0
    Width = 1227
    Height = 141
    Align = alClient
    ColCount = 25
    DefaultColWidth = 40
    DefaultRowHeight = 19
    DefaultDrawing = False
    RowCount = 8
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    TabOrder = 0
    OnDrawCell = sgValDrawCell
  end
  object Timer1: TTimer
    OnTimer = Timer1Timer
    Left = 448
    Top = 64
  end
end
