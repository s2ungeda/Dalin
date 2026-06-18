unit UExchangeData;

interface

uses
  System.Classes, System.SysUtils
  , UApiTypes
  ;

type

  TDelayInfo = record
    DelayMS : double;
    BTCMS   : double;
    XRPMS   : double;
    AmtTop1 : double;
    AmtTop2 : double;
  end;

  TExchangeData = record
    Delay : TDelayInfo;

    procedure SetDelayData( sBaseCode : string; dValue : double );
  end;

  TExhcnageDataArray = array [ TExchangeKind] of TExchangeData;

implementation

{ TExchangeData }

procedure TExchangeData.SetDelayData(sBaseCode: string; dValue: double);
begin
  Delay.DelayMS := dValue;
  if sBaseCode = 'BTC' then
    Delay.BTCMS := dValue
  else if sBaseCode = 'XRP' then
    Delay.XRPMS := dValue;

end;

end.
