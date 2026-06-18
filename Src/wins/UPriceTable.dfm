object FrmPriceTable: TFrmPriceTable
  Left = 549
  Top = 75
  Caption = 'Price Table'
  ClientHeight = 1000
  ClientWidth = 1772
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesigned
  OnClose = FormClose
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object Splitter1: TSplitter
    Left = 870
    Top = 0
    Height = 981
    ExplicitLeft = 264
    ExplicitTop = 344
    ExplicitHeight = 100
  end
  object plRight: TPanel
    Left = 873
    Top = 0
    Width = 899
    Height = 981
    Align = alClient
    BevelOuter = bvNone
    Caption = 'plRight'
    TabOrder = 0
    object plRightTop: TPanel
      Left = 0
      Top = 0
      Width = 899
      Height = 60
      Align = alTop
      BevelOuter = bvLowered
      Caption = 'plRightTop'
      TabOrder = 0
    end
    object plRightClient: TPanel
      Left = 0
      Top = 60
      Width = 899
      Height = 921
      Align = alClient
      BevelOuter = bvLowered
      Caption = 'plRightClient'
      TabOrder = 1
      object sgQuote: TStringGrid
        Left = 1
        Top = 1
        Width = 897
        Height = 919
        Align = alClient
        ColCount = 13
        DefaultRowHeight = 19
        RowCount = 24
        TabOrder = 0
      end
    end
  end
  object StatusBar1: TStatusBar
    Left = 0
    Top = 981
    Width = 1772
    Height = 19
    Panels = <>
  end
  object plLeft: TPanel
    Left = 0
    Top = 0
    Width = 870
    Height = 981
    Align = alLeft
    BevelOuter = bvNone
    Caption = 'plLeft'
    TabOrder = 2
    object plLeftTop: TPanel
      Left = 0
      Top = 0
      Width = 870
      Height = 60
      Align = alTop
      BevelOuter = bvLowered
      Caption = 'plLeftTop'
      TabOrder = 0
      DesignSize = (
        870
        60)
      object SpeedButtonRightPanel: TSpeedButton
        Left = 839
        Top = 19
        Width = 25
        Height = 21
        AllowAllUp = True
        Anchors = [akRight]
        GroupIndex = 3
        Down = True
        Flat = True
        Glyph.Data = {
          36050000424D3605000000000000360400002800000010000000100000000100
          08000000000000010000000000000000000000010000000100004A004A006200
          6200780178009F019F00BC01BC00D301D300E200E200EF00EF00F700F700FB00
          FB00FD00FD00FE00FE00FE00FE00FE00FE00FE00FE00FE00FE00FE00FE00FE00
          FE00FE00FE00FE00FE00FE00FE00FE00FE00FE00FE00FE00FE00FE00FE00FE00
          FE00FE00FE00FE00FE00FE00FE00FE00FE00FE00FE00FE00FE00FE00FE00FE00
          FE00FE00FE00FE00FE00FD00FD00FC00FC00FA00FA00F701F700F202F200EC03
          EC00E305E300D708D700C60BC600AF11AF008F188F007E1D7E006C226C006125
          6100572857004C2C4C0040304000353535003636360037373700383838003939
          39003A3A3A003B3B3B003C3C3C003D3D3D003E3E3E003F3F3F00404040004141
          4100424242004343430044444400454545004646460047474700484848004949
          49004A4A4A004B4B4B004C4C4C004D4D4D004E4E4E004F4F4F00505050005151
          5100525252005353530054545400555555005656560057575700585858005959
          59005A5A5A005B5B5B005C5C5C005D5D5D005E5E5E005F5F5F00606060006161
          6100626262006363630064646400656565006666660067676700686868006969
          69006A6A6A006B6B6B006C6C6C006D6D6D006E6E6E006F6F6F00707070007171
          7100727272007373730074747400757575007676760077777700787878007979
          79007A7A7A007B7B7B007C7C7C007D7D7D007E7E7E007F7F7F00808080008181
          8100828282008383830084848400858585008686860087878700888888008989
          89008A8A8A008B8B8B008C8C8C008D8D8D008E8E8E008F8F8F00909090009191
          9100929292009393930094949400959595009696960097979700989898009999
          99009A9A9A009B9B9B009C9C9C009D9D9D009E9E9E009F9F9F00A0A0A000A1A1
          A100A2A2A200A3A3A300A4A4A400A5A5A500A6A6A600A7A7A700A8A8A800A9A9
          A900AAAAAA00ABABAB00ACACAC00ADADAD00AEAEAE00B3B3B300BFC1BF00C8CC
          C900D0D5D200D7DDD900DEE6E100E6EDE800ECF3EE00F1F7F300F5FAF600F7FB
          F900F9FCFA00FBFDFB00FBFDFC00FBFDFC00F9FDFA00F6FCF800F4FBF600F0FA
          F300ECFAF100E9F9EF00E6F8ED00E2F7EA00DDF6E700D7F4E300D3F3E000D0F2
          DD00CEF1DB00CCF1D900C9EFD600C0EDCF00B9EBC900ADE7C000A3E4B80098E0
          AF008DDDA50085DAA0007DD89A0075D694006DD38F0067D18B0060CF84005BCE
          800055CC7B004DCA780047C8750042C672003DC46E0039C36B0036C2680033C0
          640030BE61002EBC5C002CBA590029B9550027B8510027B74E0025B5490023B5
          440023B3420022B13D0020B03B001EB1360019B2310016B32D0012B327000EB4
          21000BB41D000AB41B0009B31A0009B0190009AD19000AA318000A9717000A8C
          1700097D14000872120007680E0006640D0006650D0007690F001515151515FD
          FDFFFFFDFD1515151515151515FDFDF9F5F4F4F5F8FCFC1515151515FFFAF2F4
          F4F5F4F4F4F4FAFD151515FFF9EFF0F2F5F5F5F5F5F4F4FAFE1515FFE8E9EFF2
          EDC6C2D9F5F5F4F4FE15FBECE3E9F1F3F1D1BCBFDAF5F5F4F8FDFBE4E1E7F1F4
          F2F5D2BCBFDAF5F4F6FDFADFDFCACCCCCCCDCDBEBCC1D6F4F4FEF9D9DCBCBCBC
          BCBCBCBCBCBCCEF3F4FFF9D6D7D6D5D5D5D7D2BBBCD0E7F0F5FDF9D8D0DEE0DE
          DED5C4BCD1E8EBF0F7FD15ECCDD3E1E0DAB9BCD1E8E9EEEFF91515ECD6C8D3DF
          DECDCFE1E5E7E9EEF9151515ECD3C6CFD6DADCDBDBDFE8FA1515151515ECECCF
          C9CDCFD1D6E4E41515151515151515E7ECECECECEA1515151515}
        ExplicitLeft = 530
      end
    end
    object plLeftClient: TPanel
      Left = 0
      Top = 60
      Width = 870
      Height = 921
      Align = alClient
      BevelOuter = bvNone
      TabOrder = 1
      object Splitter2: TSplitter
        Left = 0
        Top = 488
        Width = 870
        Height = 3
        Cursor = crVSplit
        Align = alTop
        ExplicitLeft = 1
        ExplicitTop = 201
        ExplicitWidth = 458
      end
      object plLeftClientTop: TPanel
        Left = 0
        Top = 0
        Width = 870
        Height = 488
        Align = alTop
        BevelOuter = bvLowered
        Caption = 'plLeftClientTop'
        TabOrder = 0
        object sgKimp: TStringGrid
          Left = 1
          Top = 1
          Width = 868
          Height = 486
          Align = alClient
          ColCount = 13
          DefaultRowHeight = 19
          RowCount = 24
          TabOrder = 0
        end
      end
      object plLeftClientClient: TPanel
        Left = 0
        Top = 491
        Width = 870
        Height = 430
        Align = alClient
        BevelOuter = bvLowered
        Caption = 'plLeftClientClient'
        TabOrder = 1
        object sgInOut: TStringGrid
          Left = 1
          Top = 1
          Width = 868
          Height = 428
          Align = alClient
          ColCount = 13
          DefaultRowHeight = 19
          RowCount = 24
          TabOrder = 0
        end
      end
    end
  end
end
