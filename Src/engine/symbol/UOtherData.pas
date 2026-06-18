unit UOtherData;

interface

uses
  System.Classes, System.SysUtils

  , UApiTypes

  ;

type

  TWCDData = class( TCollectionItem )
  private
    FTimStr  : string;
    FName: string;

  public
    Price   : array [TMajorSymbolKind, TExchangeKind ] of double;
    Amount  : array [TMajorSymbolKind, TExchangeKind ] of double;
    WCDPrice: array [TMajorSymbolKind, TExchangeKind ] of double;
    KipPrice: array [TMajorSymbolKind, TExchangeKind ] of double;
    RpsntWCD: array [TExchangeKind] of double;
    RpsntKIP: array [TExchangeKind] of double;

    m, d : word;

    procedure CalcWCD;
    procedure CalcKIP;
    procedure CalcRpsntWCD( aExKind : TExchangeKind );
    procedure CalcRpsntKIP( aExKind : TExchangeKind );

    property Name : string read FName write FName;
    property TimStr : string read FTimStr write FTimStr;
  end;

  TWCDDataList = class( TCollection )
  private
    function GetWCDS(i: integer): TWCDData;
  public
    Constructor Create;
    function New( sTime : string ): TWCDData;
    function Find( sTime : string ) : TWCDData;
    property WCDs[ i : integer] : TWCDData read GetWCDS;
  end;

implementation

uses
  GApp
  , math
  ;

{ TOtherData }


{ TTWCDDataList }

constructor TWCDDataList.Create;
begin
  inherited Create( TWCDData );
end;

function TWCDDataList.Find(sTime: string): TWCDData;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to Count-1 do
    if GetWCDS(i).FTimStr = sTime then
    begin
      Result := GetWCDS(i);
      break;
    end;
end;

function TWCDDataList.GetWCDS(i: integer): TWCDData;
begin
  if ( i < 0 ) or ( i >= count ) then
    Result := nil
  else
    Result := Items[i] as TWCDData;
end;

function TWCDDataList.New(sTime: string): TWCDData;
begin
  Result := Add as TWCDData;
  Result.TimStr := sTime;
end;

{ TWCDData }


procedure TWCDData.CalcKIP;
  function kip( aPrice, aLast : double ) : double;
  var
    dEx : double;
  begin
     dEx :=  Max( aPrice * App.Engine.ApiManager.ExRate.Value , 1 );
    if IsZero( dEx ) then
      Result := 1
    else
      Result := ( aLast - dEx) / dEx * 100;

  end;
begin
  KipPrice[msBTC][ekUpbit]  := kip( Price[msBTC][ekBinance], Price[msBTC][ekUpbit] );
  KipPrice[msETH][ekUpbit]  := kip( Price[msETH][ekBinance], Price[msETH][ekUpbit] );

  KipPrice[msBTC][ekBithumb]:= kip( Price[msBTC][ekBinance], Price[msBTC][ekBithumb] );
  KipPrice[msETH][ekBithumb]:= kip( Price[msETH][ekBinance], Price[msETH][ekBithumb] );
end;

procedure TWCDData.CalcRpsntKIP( aExKind : TExchangeKind );
var
  dVal, dAmt : double;
begin
  dAmt := Amount[msBTC][aExKind] + Amount[msETH][aExKind];
  if dAmt > 0 then
    dVal := ( Amount[msBTC][aExKind] * KipPrice[msBTC][aExKind]
            + Amount[msETH][aExKind] * KipPrice[msETH][aExKind] ) / dAmt
  else
    dVal := 1;

  RpsntKIP[aExKind] := dVal;

end;

procedure TWCDData.CalcRpsntWCD( aExKind : TExchangeKind );
var
  dVal, dAmt : double;
begin
  dAmt := Amount[msBTC][aExKind] + Amount[msETH][aExKind];
  if dAmt > 0 then
    dVal := ( Amount[msBTC][aExKind] * WCDPrice[msBTC][aExKind]
            + Amount[msETH][aExKind] * WCDPrice[msETH][aExKind] ) / dAmt
  else
    dVal := 1;

  RpsntWCD[aExKind] := dVal;

end;

procedure TWCDData.CalcWCD;

  function wcd( aPrice, aLast : double ) : double;
  begin
    if IsZero( aPrice ) then
      Result := 1
    else
      Result := ( 1/ aPrice) * aLast;
  end;

begin

  WCDPrice[msBTC][ekUpbit]  := wcd( Price[msBTC][ekBinance], Price[msBTC][ekUpbit] );
  WCDPrice[msETH][ekUpbit]  := wcd( Price[msETH][ekBinance], Price[msETH][ekUpbit] );

  WCDPrice[msBTC][ekBithumb]:= wcd( Price[msBTC][ekBinance], Price[msBTC][ekBithumb] );
  WCDPrice[msETH][ekBithumb]:= wcd( Price[msETH][ekBinance], Price[msETH][ekBithumb] );

end;




end.
