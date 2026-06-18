object FrmInputEntropy: TFrmInputEntropy
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Entropy'
  ClientHeight = 161
  ClientWidth = 420
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -18
  Font.Name = 'Segoe UI'
  Font.Style = []
  KeyPreview = True
  Position = poScreenCenter
  OnCreate = FormCreate
  OnKeyUp = FormKeyUp
  PixelsPerInch = 144
  TextHeight = 25
  object Label1: TLabel
    Left = 10
    Top = 127
    Width = 384
    Height = 25
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    Caption = '* '#51060#51221#48372#45716' '#51200#51109#46104#51648' '#50506#51020', '#48516#49892#49884' '#52293#51076#51648#51648' '#50506#51020
  end
  object Label2: TLabel
    Left = 10
    Top = 99
    Width = 323
    Height = 25
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    Caption = '* '#47196#46300'/'#51200#51109#50640' '#49324#50857#54624' '#50516#54840#47484' '#51077#47141#54616#49464#50836
  end
  object edtInput: TLabeledEdit
    Left = 72
    Top = 22
    Width = 193
    Height = 33
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    EditLabel.Width = 36
    EditLabel.Height = 33
    EditLabel.Margins.Left = 5
    EditLabel.Margins.Top = 5
    EditLabel.Margins.Right = 5
    EditLabel.Margins.Bottom = 5
    EditLabel.Caption = #51077#47141
    LabelPosition = lpLeft
    PasswordChar = '*'
    TabOrder = 0
    Text = ''
  end
  object edtConfirm: TLabeledEdit
    Left = 72
    Top = 65
    Width = 193
    Height = 33
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    EditLabel.Width = 36
    EditLabel.Height = 33
    EditLabel.Margins.Left = 5
    EditLabel.Margins.Top = 5
    EditLabel.Margins.Right = 5
    EditLabel.Margins.Bottom = 5
    EditLabel.Caption = #54869#51064
    LabelPosition = lpLeft
    PasswordChar = '*'
    TabOrder = 1
    Text = ''
  end
  object Button1: TButton
    Left = 313
    Top = 22
    Width = 83
    Height = 33
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    Caption = #54869#51064
    TabOrder = 2
    OnClick = Button1Click
  end
end
