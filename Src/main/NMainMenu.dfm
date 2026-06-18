object DataModule1: TDataModule1
  OnCreate = DataModuleCreate
  Height = 258
  Width = 648
  PixelsPerInch = 144
  object MainMenu1: TMainMenu
    Left = 168
    Top = 132
    object nFile: TMenuItem
      Caption = #54028#51068
      object Message1: TMenuItem
        Caption = 'Message'
        OnClick = Message1Click
      end
      object N12: TMenuItem
        Tag = 1
        Caption = #54868#47732#51200#51109
        OnClick = Message1Click
      end
      object N7: TMenuItem
        Caption = '-'
      end
      object N1: TMenuItem
        Tag = 2
        Caption = #51333#47308
        OnClick = Message1Click
      end
    end
    object nAccount: TMenuItem
      Caption = #44144#47000#49548
      object nExchange: TMenuItem
        Caption = #51077#52636#44552#54788#54889#54364
        OnClick = nExchangeClick
      end
      object N15: TMenuItem
        Tag = 2
        Caption = #52636#44552
        OnClick = nExchangeClick
      end
      object N16: TMenuItem
        Tag = 3
        Caption = #44397#45236#44228#51340' '#51077#52636#44552
        OnClick = nExchangeClick
      end
      object N2: TMenuItem
        Tag = 4
        Caption = #51077#44552#51452#49548#44288#47532
        OnClick = nExchangeClick
      end
      object N8: TMenuItem
        Tag = 5
        Caption = #52636#44552#54728#50857#51452#49548#51312#54924
        OnClick = nExchangeClick
      end
    end
    object nOrder: TMenuItem
      Caption = #51452#47928
      object N5: TMenuItem
        Caption = #51452#47928#52285
        OnClick = N5Click
      end
      object N3: TMenuItem
        Tag = 1
        Caption = #51452#47928#47532#49828#53944
        OnClick = N5Click
      end
      object N4: TMenuItem
        Tag = 2
        Caption = #51333#54633#51092#44256
        OnClick = N5Click
      end
      object EST2: TMenuItem
        Tag = 10
        Caption = #47680#54000#50724#45908'_TEST'
        OnClick = N5Click
      end
      object N9: TMenuItem
        Caption = '-'
      end
      object N18: TMenuItem
        Tag = 20
        Caption = 'Gold Lode'
        OnClick = N5Click
      end
      object KIP1: TMenuItem
        Tag = 4
        Caption = 'KIP OLD'
        OnClick = N5Click
      end
      object KIPSP1: TMenuItem
        Tag = 7
        Caption = 'KIP'
        OnClick = N5Click
      end
      object NEWPKENTRY1: TMenuItem
        Tag = 8
        Caption = 'PK ENTRY'
        OnClick = N5Click
      end
      object NEWPKEXIT1: TMenuItem
        Tag = 9
        Caption = 'PK EXIT'
        OnClick = N5Click
      end
    end
    object N13: TMenuItem
      Caption = #49444#51221
      object N17: TMenuItem
        Caption = #49444#51221'('#54620#46020','#49688#49688#47308')'
        OnClick = N17Click
      end
      object N19: TMenuItem
        Tag = 1
        Caption = #51088#46041#51452#47928#49444#51221
        OnClick = N17Click
      end
    end
    object nQuote: TMenuItem
      Caption = #49884#49464
      object Kimp1: TMenuItem
        Caption = 'Kimp '#54788#54889#54364
        OnClick = Kimp1Click
      end
      object N6: TMenuItem
        Tag = 1
        Caption = #49884#49464#47784#45768#53552#47553
        OnClick = Kimp1Click
      end
    end
    object ool1: TMenuItem
      Caption = 'Tool'
      object ExRate1: TMenuItem
        Caption = 'ExRate'
        OnClick = readme1Click
      end
      object Rest1: TMenuItem
        Tag = 1
        Caption = 'Rest'
        OnClick = readme1Click
      end
      object KeyManager1: TMenuItem
        Tag = 2
        Caption = 'KeyManager'
        OnClick = readme1Click
      end
      object TMenuItem
        Caption = '-'
      end
      object Readme1: TMenuItem
        Tag = 3
        Caption = 'Readme'
        OnClick = readme1Click
      end
    end
  end
end
