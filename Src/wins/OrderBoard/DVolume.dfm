object FrmVolume: TFrmVolume
  Left = 0
  Top = 0
  BorderIcons = [biMinimize, biMaximize]
  BorderStyle = bsDialog
  Caption = 'Volume'
  ClientHeight = 107
  ClientWidth = 233
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -17
  Font.Name = 'Tahoma'
  Font.Style = []
  Position = poOwnerFormCenter
  PixelsPerInch = 144
  TextHeight = 21
  object edtVolume: TEdit
    Left = 12
    Top = 12
    Width = 182
    Height = 29
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    ImeName = 'Microsoft IME 2003'
    TabOrder = 0
    OnKeyPress = edtVolumeKeyPress
  end
  object Button1: TButton
    Left = 93
    Top = 57
    Width = 113
    Height = 38
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 1
  end
end
